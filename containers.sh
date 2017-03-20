#!/bin/bash
if [ "$EUID" -eq 0 ]
then
    echo "Please don't run the script as root!"
    echo "Remove sudo/exit root user mode."
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
GRAPHITE_IMAGE_VERSION="0.9.15"
GRAPHITE_IMAGE=nickstenning/graphite:$GRAPHITE_IMAGE_VERSION
GRAPHITE_CONTAINER_NAME="graphite"

# Backend
BACKEND_IMAGE_NAME="backend"
BACKEND_IMAGE_VERSION="latest"
BACKEND_IMAGE=$BACKEND_IMAGE_NAME:$BACKEND_IMAGE_VERSION
BACKEND_CONTAINER_NAME="backend"

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

GRAFANA_VOLUME_TARGET=$HOME/grafana
CASSANDRA_VOLUME_TARGET=$HOME/cassandra

cass_build=0
function cassandra {
    # Cassandra container
    # Port: 9042
    if [[ "$(docker images -q $CASSANDRA_IMAGE_NAME 2> /dev/null)" == "" ]]; then
        echo -e $YELLOW"### Creating cassandra container"$RESET
        docker build -t $CASSANDRA_IMAGE_NAME ./Cassandra
    fi
    if [ ! "$(docker ps --all | grep $CASSANDRA_CONTAINER_NAME)" ]; then
        echo -e $GREEN"### Starting cassandra container"$RESET
        docker run \
            --restart=always \
            --name $CASSANDRA_CONTAINER_NAME \
            -p $CASSANDRA_PORT:$CASSANDRA_PORT \
            -d $CASSANDRA_IMAGE
        cass_build=1
    else
        echo -e $GREEN"### Restarting cassandra container"$RESET
        docker restart $CASSANDRA_CONTAINER_NAME
    fi
}

function graphite {
        # Graphite container
        # Ports: Receive=2003, WebApp=2000
        if [ ! "$(docker ps --all | grep $GRAPHITE_CONTAINER_NAME)" ]; then
            echo -e $YELLOW"### Creating graphite container"$RESET
            docker run \
                --restart=always \
                --name $GRAPHITE_CONTAINER_NAME \
                -p 2003:2003 -p 2000:80 \
                -d $GRAPHITE_IMAGE
        else
            echo -e $GREEN"### Restarting graphite container"$RESET
            docker restart $GRAPHITE_CONTAINER_NAME
        fi
}

function backend {
    echo "The back end container is currently disabled"
    # Backend container
    # Port: 8080
    # echo -e $YELLOW"### Cleaning backend container"$RESET
    # if [[ "$(docker ps -all | grep $BACKEND_NAME)" ]]; then
    #     clean_container $BACKEND_NAME
    # fi
    # if [[ "$(docker images -q $BACKEND 2> /dev/null)" == "" ]]; then
    #     docker rmi $BACKEND
    # fi
    # echo -e $YELLOW"### Compiling backend container"$RESET
    # (cd ./QvantelBackend; sbt assembly)
    # echo -e $YELLOW"### Building backend container"$RESET
    # docker build -t $BACKEND_NAME ./QvantelBackend
    # echo -e $GREEN"### Starting backend container"$RESET
    # docker run \
        # --restart=always \
        # --name $BACKEND_NAME \
        # -p 8080:8080 \
        # -d $BACKEND
}

function cdrgenerator {
    # CDRGenerator container
    if [ -n "$(docker ps | grep $CASSANDRA_CONTAINER_NAME)" ]
    then
        echo "Waiting for port to open"
        while [ -n "$(docker exec -it $CASSANDRA_CONTAINER_NAME cqlsh -e exit 2>&1 | grep '\(e\|E\)rror')" ]
        do
            sleep 0.1
        done
        echo "Cqlsh is up and running"
        if [ "$cass_build" -eq 1 ]; then
            echo "Running schema"
            docker exec -it $CASSANDRA_CONTAINER_NAME cqlsh -f /schema.cql
            cass_build=0
        fi
    else
        echo $RED"ERROR: Cassandra container is not running, will not start DBConnector container"$RESET
        exit 1
    fi

    if [[ "$(docker ps --all | grep $CDRGENERATOR_CONTAINER_NAME)" ]]; then
    	echo -e $YELLOW"### Cleaning CDRGenerator container"$RESET
	clean_container $CDRGENERATOR_CONTAINER_NAME
    fi
    if [[ "$(docker images -q $CDRGENERATOR 2> /dev/null)" == "" ]]; then
        docker rmi $CDRGENERATOR_IMAGE
    fi
    echo -e $YELLOW"### Compiling CDRGenerator container"$RESET
    (cd ./QvantelCDRGenerator; sbt assembly)
    
    echo -e $YELLOW"### Building CDRGenerator container"$RESET
    docker build -t $CDRGENERATOR_IMAGE_NAME ./QvantelCDRGenerator
    
    echo -e $GREEN"### Starting CDRGenerator container"$RESET
    docker run $DOCKER_OPTS \
        --restart=always \
        --net=host \
        --name $CDRGENERATOR_CONTAINER_NAME \
        -d $CDRGENERATOR_IMAGE
}

function dbconnector {
    # DBConnector container
    if [[ "$(docker ps --all | grep $DBCONNECTOR_CONTAINER_NAME)" ]]; then
        echo -e $YELLOW"### Cleaning DBConnector container"$RESET
	clean_container $DBCONNECTOR_CONTAINER_NAME
    fi
    if [[ $(docker images -q $DBCONNECTOR_IMAGE_NAME 2> /dev/null) == "" ]]; then
        echo -e $YELLOW"### Cleaning DBConnector image"$RESET
        docker rmi $DBCONNECTOR_IMAGE
    fi
    
    echo -e $YELLOW"### Compiling DBConnector program"$RESET
    (cd ./QvantelDBConnector; sbt assembly)
    
    echo -e $YELLOW"### Building DBConnector image"$RESET
    docker build -t $DBCONNECTOR_IMAGE_NAME ./QvantelDBConnector
    
    echo -e $GREEN"### Starting DBConnector container"$RESET
    docker run $DOCKER_OPTS \
        --restart=always \
        --net=host \
        --name $DBCONNECTOR_CONTAINER_NAME \
        -d $DBCONNECTOR_IMAGE
}

function frontend {
    # Frontend container
    # Port: 3000
    if [[ "$(docker ps --all | grep $FRONTEND_CONTAINER_NAME)" ]]; then
        echo -e $YELLOW"### Cleaning frontend container"$RESET
	clean_container $FRONTEND_CONTAINER_NAME
    fi
    if [[ "$(docker images -q $FRONTEND_IMAGE_NAME 2> /dev/null)" == "" ]]; then
        echo -e $YELLOW"### Cleaning frontend image"$RESET
        docker rmi $FRONTEND_IMAGE_NAME
    fi

    echo -e $YELLOW"### Building frontend plugins"$RESET
    npm --prefix ./QvantelFrontend run build
    echo -e $YELLOW"### Building frontend image"$RESET
    docker build -t $FRONTEND_IMAGE_NAME ./QvantelFrontend

    echo -e $GREEN"### Starting frontend container"$RESET
    docker run \
        --restart=always \
        -p 3000:3000 \
        --name $FRONTEND_CONTAINER_NAME \
        -d $FRONTEND_IMAGE
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
    "help"|*)
        echo -e $usage
    ;;

esac

duration=$(( SECONDS - start ))
echo -e $CYAN"< Execution took $duration seconds >"$RESET
