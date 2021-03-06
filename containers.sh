#!/bin/bash
if [ "$EUID" -eq 0 ]
then
    echo "Please don't run the script as root!"
    echo "Remove sudo/exit root user mode."
    exit 1
fi
s=$(./before_install.sh)
if [ ! -z "$s" ]; then
    echo "$s"
    exit 1
fi
start=$SECONDS

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

# Docker opts
# If run on a Mac, add moby host
DOCKER_OPTS=""
if [[ $OSTYPE == *"darwin"* ]]; then
    DOCKER_OPTS=$DOCKER_OPTS" --add-host=moby:127.0.0.1"
fi

# Cassandra
CASSANDRA_IMAGE_VERSION="latest"
CASSANDRA_IMAGE_NAME="cassandra_qvantel"
CASSANDRA_IMAGE=$CASSANDRA_IMAGE_NAME:$CASSANDRA_IMAGE_VERSION
CASSANDRA_CONTAINER_NAME="cassandra_qvantel"
CASSANDRA_PORT=9042

# Graphite
GRAPHITE_IMAGE_NAME="graphite"
GRAPHITE_IMAGE_VERSION="latest"
GRAPHITE_IMAGE=hopsoft/graphite-statsd:$GRAPHITE_IMAGE_VERSION
GRAPHITE_CONTAINER_NAME="graphite"

# CDRGenerator
CDRGENERATOR_IMAGE_NAME="cdrgenerator"
CDRGENERATOR_IMAGE_VERSION="latest"
CDRGENERATOR_IMAGE=$CDRGENERATOR_IMAGE_NAME:$CDRGENERATOR_IMAGE_VERSION
CDRGENERATOR_CONTAINER_NAME="cdrgenerator"

# DBConnector
DBCONNECTOR_IMAGE_NAME="dbconnector"
DBCONNECTOR_IMAGE_VERSION="latest"
DBCONNECTOR_IMAGE=$DBCONNECTOR_IMAGE_NAME:$DBCONNECTOR_IMAGE_VERSION
DBCONNECTOR_CONTAINER_NAME="dbconnector"

# Frontend
FRONTEND_IMAGE_NAME="frontend"
FRONTEND_IMAGE_VERSION="latest"
FRONTEND_IMAGE=$FRONTEND_IMAGE_NAME:$FRONTEND_IMAGE_VERSION
FRONTEND_CONTAINER_NAME="frontend"

usage="Usage: [start|stop|clean|help]
              start [(cass|cassandra)|(cdr|cdrgenerator)|graphite|(dbc|dbconnector)|frontend|"

function cassandra {
    # Cassandra container
    # Port: 9042
    build=0
    if  [[ -z "$(docker images -q $CASSANDRA_IMAGE_NAME 2> /dev/null)" ]] || \
        # If schema file has been updated.
        [[ "$(md5sum ./Cassandra/schema.cql)" != "$(cat ./.schema_md5sum 2> /dev/null)" ]] || \
        # No existing cassandra container, even though the schema files does not diff?(AKA Clean)
        # Force cassandra to re-init.
        [[ ! "$(docker ps --all | grep $CASSANDRA_CONTAINER_NAME)" ]]; then
        echo -e $YELLOW"### Creating cassandra container"$RESET
        docker build -t $CASSANDRA_IMAGE_NAME ./Cassandra
        build=1
    fi
    if [ ! "$(docker ps --all | grep $CASSANDRA_CONTAINER_NAME)" ]; then
        echo -e $GREEN"### Starting cassandra container"$RESET
        docker run \
            --restart=always \
            --name $CASSANDRA_CONTAINER_NAME \
            -p $CASSANDRA_PORT:$CASSANDRA_PORT \
            -d $CASSANDRA_IMAGE
    else
        echo -e $GREEN"### Restarting cassandra container"$RESET
        docker restart $CASSANDRA_CONTAINER_NAME
    fi
    verify_cassandra_cdrtables $build
}

function graphite {
        # Graphite container
        # Ports: Receive=2003, WebApp=2000
        if [ ! "$(docker ps --all | grep $GRAPHITE_CONTAINER_NAME)" ]; then
            echo -e $YELLOW"### Creating graphite container"$RESET
            docker run \
                --restart=always \
                --name $GRAPHITE_CONTAINER_NAME \
                -p 2003-2004:2003-2004 -p 2000:80 \
                -p 8125:8125/udp -p 8126:8126 -p 2023-2024:2023-2024 \
                -d $GRAPHITE_IMAGE
        else
            echo -e $GREEN"### Restarting graphite container"$RESET
            docker restart $GRAPHITE_CONTAINER_NAME
        fi
}


function verify_cassandra_cdrtables {
    force_build=$1 # If building, don't check hashes. BUILD IT!
    if [ -n "$(docker ps | grep $CASSANDRA_CONTAINER_NAME)" ]
    then
        wait_until_cassandra_is_up
        if [[ $force_build -eq 1 ]] || [[ "$(md5sum ./Cassandra/schema.cql)" != "$(cat ./.schema_md5sum 2> /dev/null)" ]]
        then
            echo "Running schema"
            docker exec -it $CASSANDRA_CONTAINER_NAME cqlsh -e "DROP KEYSPACE IF EXISTS qvantel;"
            docker exec -it $CASSANDRA_CONTAINER_NAME cqlsh -f /schema.cql
            md5sum ./Cassandra/schema.cql > ./.schema_md5sum
        fi
    else
        echo $RED"ERROR: Cassandra container is not running, will not start container"$RESET
        exit 1
    fi
}

function wait_until_cassandra_is_up {
    echo "Waiting for cassandra port to open"
    while [ -n "$(docker exec -it $CASSANDRA_CONTAINER_NAME cqlsh -e exit 2>&1 | grep '\(e\|E\)rror')" ]
    do
        sleep 0.1
    done
    echo "Cqlsh is up and running"
}


function cdrgenerator {
    # CDRGenerator container
    wait_until_cassandra_is_up
    if [[ "$(docker ps --all | grep $CDRGENERATOR_CONTAINER_NAME)" ]]; then
    	echo -e $YELLOW"### Cleaning CDRGenerator container"$RESET
	clean_container $CDRGENERATOR_CONTAINER_NAME
    fi
    if [[ -z "$(docker images -q $CDRGENERATOR 2> /dev/null)" ]]; then
        docker rmi $CDRGENERATOR_IMAGE
    fi
    echo -e $YELLOW"### Compiling CDRGenerator container"$RESET
    sbt_fail=0
    (cd ./orcd-generator; sbt assembly) || sbt_fail=1
    
    if [[ $sbt_fail -ne 0 ]];
    then
        echo -e $RED"### Failed to compile CDRGenerator"$RESET
    else
        echo -e $YELLOW"### Building CDRGenerator container"$RESET
        docker build -t $CDRGENERATOR_IMAGE_NAME ./orcd-generator
    
        echo -e $GREEN"### Starting CDRGenerator container"$RESET
        docker run $DOCKER_OPTS \
            --restart=always \
            --net=host \
            --name $CDRGENERATOR_CONTAINER_NAME \
            -d $CDRGENERATOR_IMAGE
    fi
}

function dbconnector {
    # DBConnector container
    wait_until_cassandra_is_up
    if [[ "$(docker ps --all | grep $DBCONNECTOR_CONTAINER_NAME)" ]]; then
        echo -e $YELLOW"### Cleaning DBConnector container"$RESET
	clean_container $DBCONNECTOR_CONTAINER_NAME
    fi
    if [[ -z "$(docker images -q $DBCONNECTOR_IMAGE_NAME 2> /dev/null)" ]]; then
        echo -e $YELLOW"### Cleaning DBConnector image"$RESET
        docker rmi $DBCONNECTOR_IMAGE
    fi
    
    echo -e $YELLOW"### Compiling DBConnector program"$RESET
    sbt_fail=0
    (cd ./orcd-dbconnector; sbt assembly) || sbt_fail=1
    
    if [[ $sbt_fail -ne 0 ]];
    then
        echo -e $RED"### Failed to compile DBConnector"$RESET
    else
        echo -e $YELLOW"### Building DBConnector image"$RESET
        docker build -t $DBCONNECTOR_IMAGE_NAME ./orcd-dbconnector
    
        echo -e $GREEN"### Starting DBConnector container"$RESET
        docker run $DOCKER_OPTS \
            --restart=always \
            --net=host \
            --name $DBCONNECTOR_CONTAINER_NAME \
            -d $DBCONNECTOR_IMAGE
    fi
}

function frontend {
    # Frontend container
    # Port: 3000
    if [[ "$(docker ps --all | grep $FRONTEND_CONTAINER_NAME)" ]]; then
        echo -e $YELLOW"### Cleaning frontend container"$RESET
	clean_container $FRONTEND_CONTAINER_NAME
    fi
    if [[ -z "$(docker images -q $FRONTEND_IMAGE_NAME 2> /dev/null)" ]]; then
        echo -e $YELLOW"### Cleaning frontend image"$RESET
        docker rmi $FRONTEND_IMAGE_NAME
    fi

    npm_fail=0
    echo -e $YELLOW"### Building frontend plugins"$RESET
    npm --prefix ./orcd-frontend run build || npm_fail=1
    if [[ $npm_fail -ne 0 ]]; then
        echo -e $RED"### Failed to build frontend plugins"$RESET
    else
        echo -e $YELLOW"### Building frontend image"$RESET
        docker build -t $FRONTEND_IMAGE_NAME ./orcd-frontend

        echo -e $GREEN"### Starting frontend container"$RESET
        docker run \
            --restart=always \
            -p 3000:3000 \
            --name $FRONTEND_CONTAINER_NAME \
            -d $FRONTEND_IMAGE
    fi
}

function stop_container {
    # Takes 1 arg, string of container
    echo -e $RED"Stopping $1"$RESET
    docker stop "$1"
}

function clean_container {
    # Takes 1 arg, string of container
    echo -e $RED"Stopping $1"$RESET
    docker stop "$1" &> /dev/null
    echo -e $RED"Removing $1"$RESET
    docker rm "$1" &> /dev/null
}

function load_order {
    # Be careful when editing the order
    # If you know what you're doing, great.
    cassandra
    graphite
    cdrgenerator
    dbconnector
    frontend
 }

function verify_containers {
    containers=("$CASSANDRA_CONTAINER_NAME $GRAPHITE_CONTAINER_NAME $CDRGENERATOR_CONTAINER_NAME $DBCONNECTOR_CONTAINER_NAME $FRONTEND_CONTAINER_NAME")

    for container in $containers
    do
      if [ -n "$(docker ps | grep $container)" ]; then
          echo -e $GREEN"$container exists"$RESET
      else
          echo -e $RED"$container does not exist"$RESET
          exit 1
      fi
    done
}

# Script entry point
case "$1"
in
    "start")
        case "$2"
        in
            "cass"|"cassandra")
                cassandra
            ;;
            "cdr"|"cdrgenerator")
                cdrgenerator
            ;;
            "graphite")
                graphite
            ;;
            "dbc"|"dbconnector")
                dbconnector
            ;;
            "frontend")
                frontend
            ;;
            *)
                if [ -z "$2" ]; then
                    load_order
                else
                    echo $RED"There's no target container named $2"$RESET
                fi
            ;;
         esac
    ;;
    "stop")
        case "$2"
        in
            "cass"|"cassandra")
                stop_container $CASSANDRA_CONTAINER_NAME
            ;;
            "cdr"|"cdrgenerator")
                stop_container $CDRGENERATOR_CONTAINER_NAME
            ;;
            "graphite")
                stop_container $GRAPHITE_CONTAINER_NAME
            ;;
            "dbc"|"dbconnector")
                stop_container $DBCONNECTOR_CONTAINER_NAME
            ;;
            "backend")
                stop_container $BACKEND_CONTAINER_NAME
            ;;
            "frontend")
                stop_container $FRONTEND_CONTAINER_NAME
            ;;
            *)
                if [ -z "$2" ]; then
                    echo -e $RED"Stopping containers"$RESET
                    docker stop \
                        $CASSANDRA_CONTAINER_NAME \
                        $GRAPHITE_CONTAINER_NAME \
                        $CDRGENERATOR_CONTAINER_NAME \
                        $DBCONNECTOR_CONTAINER_NAME \
                        $FRONTEND_CONTAINER_NAME \
                        > /dev/null
                else
                    echo $RED"There's no target container named $2"$RESET
                fi
            ;;
        esac
    ;;
    "clean")
        case "$2"
        in
            "cass"|"cassandra")
                clean_container $CASSANDRA_CONTAINER_NAME
            ;;
            "cdr"|"cdrgenerator")
                clean_container $CDRGENERATOR_CONTAINER_NAME
            ;;
            "graphite")
                clean_container $GRAPHITE_CONTAINER_NAME
            ;;
            "dbc"|"dbconnector")
                clean_container $DBCONNECTOR_CONTAINER_NAME
            ;;
            "backend")
                clean_container $BACKEND_CONTAINER_NAME
            ;;
            "frontend")
                clean_container $FRONTEND_CONTAINER_NAME
            ;;
            *)
                if [ -z "$2" ]; then
                    echo -e $RED"Stopping containers"$RESET
                    docker stop \
                        $CASSANDRA_CONTAINER_NAME \
                        $GRAPHITE_CONTAINER_NAME \
                        $CDRGENERATOR_CONTAINER_NAME \
                        $DBCONNECTOR_CONTAINER_NAME \
                        $FRONTEND_CONTAINER_NAME \
                        > /dev/null
                    echo -e $RED"Removing containers"$RESET
                    docker rm \
                        $CASSANDRA_CONTAINER_NAME \
                        $GRAPHITE_CONTAINER_NAME \
                        $CDRGENERATOR_CONTAINER_NAME \
			$DBCONNECTOR_CONTAINER_NAME \
			$FRONTEND_CONTAINER_NAME \
			> /dev/null
                else
                    echo $RED"There's no target container named $2"$RESET
                fi
            ;;
        esac
    ;;
    "verify")
      verify_containers
    ;;
    "help"|*)
        echo -e $usage
    ;;

esac

duration=$(( SECONDS - start ))
echo -e $CYAN"< Execution took $duration seconds >"$RESET
