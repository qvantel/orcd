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
CASSANDRA_VERSION="3.9"
CASSANDRA=cassandra:$CASSANDRA_VERSION
CASSANDRA_PORT=9042

# Graphite
GRAPHITE_VERSION="0.9.15"
GRAPHITE=nickstenning/graphite:$GRAPHITE_VERSION

# Backend
BACKEND_VERSION="latest"
BACKEND=backend:$BACKEND_VERSION

# CDRGenerator
CDRGENERATOR_VERSION="latest"
CDRGENERATOR=cdrgenerator:$CDRGENERATOR_VERSION
CDRGENERATOR_CONTAINER_NAME="cdrgenerator"


# DBConnector
DBCONNECTOR_VERSION="latest"
DBCONNECTOR=dbconnector:$DBCONNECTOR_VERSION

# Grafana
GRAFANA_VERSION="4.1.1"
GRAFANA=grafana/grafana:$GRAFANA_VERSION

usage="Usage: [start|stop|clean|help]
              start [(cass|cassandra)|(cdr|cdrgenerator)|graphite|(dbc|dbconnector)|frontend|"

GRAFANA_VOLUME_TARGET=$HOME/grafana
CASSANDRA_VOLUME_TARGET=$HOME/cassandra

function cassandra {
    # Cassandra container
    # Port: 9042
    if [ ! "$(docker ps --all | grep cassandra)" ]; then
        echo -e $YELLOW"### Creating cassandra container"$RESET
        docker build -t cassandra ./Cassandra
        docker run \
            --restart=always \
            --name cassandra \
            -p $CASSANDRA_PORT:$CASSANDRA_PORT \
            -d cassandra
        export cass_build=1
    else
        echo -e $GREEN"### Restarting cassandra container"$RESET
        docker restart cassandra
        export cass_build=0
    fi
}

function graphite {
        # Graphite container
        # Ports: Receive=2003, WebApp=2000
        if [ ! "$(docker ps --all | grep graphite)" ]; then
            echo -e $YELLOW"### Creating graphite container"$RESET
            docker run \
                --restart=always \
                --name graphite \
                -p 2003:2003 -p 2000:80 \
                -d $GRAPHITE
        else
            echo -e $GREEN"### Restarting graphite container"$RESET
            docker restart graphite
        fi
}

function backend {
    echo "The back end container is currently disabled"
    # Backend container
    # Port: 8080
    # echo -e $YELLOW"### Cleaning backend container"$RESET
    # if [[ "$(docker ps | grep backend)" ]]; then
    #     docker stop backend
    # fi
    # if [[ "$(docker ps --all | grep backend)" ]]; then
    #     docker rm backend
    # fi
    # if [[ "$(docker images -q $BACKEND 2> /dev/null)" == "" ]]; then
    #     docker rmi $BACKEND
    # fi
    # echo -e $YELLOW"### Compiling backend container"$RESET
    # (cd ./QvantelBackend; sbt assembly)
    # echo -e $YELLOW"### Building backend container"$RESET
    # docker build -t backend ./QvantelBackend
    # echo -e $GREEN"### Starting backend container"$RESET
    # docker run \
        # --restart=always \
        # --name backend \
        # -p 8080:8080 \
        # -d $BACKEND
}

function cdrgenerator {
    # CDRGenerator container
    if [ -n "$(docker ps | grep cassandra)" ]
    then
      echo "Waiting for port to open"
      while [ -n "$(docker exec -it cassandra cqlsh -e exit 2>&1 | grep '\(e\|E\)rror')" ]
      do
        sleep 1
      done
      echo "Cqlsh is up and running"
      if [ "$cass_build" -eq 1 ]; then
          echo "Running schema"
          docker exec -it cassandra cqlsh -f /schema.cql
          cass_build=0
      fi
    fi

    echo -e $YELLOW"### Cleaning CDRGenerator container"$RESET
    if [[ "$(docker ps | grep $CDRGENERATOR)" ]]; then
        docker stop $CDRGENERATOR_CONTAINER_NAME
    fi
    if [[ "$(docker ps --all | grep $CDRGENERATOR)" ]]; then
        docker rm $CDRGENERATOR_CONTAINER_NAME
    fi
    if [[ "$(docker images -q $CDRGENERATOR 2> /dev/null)" == "" ]]; then
        docker rmi $CDRGENERATOR_CONTAINER_NAME
    fi
    echo -e $YELLOW"### Compiling CDRGenerator container"$RESET
    (cd ./QvantelCDRGenerator; sbt assembly)
    echo -e $YELLOW"### Building CDRGenerator container"$RESET
    docker build -t $CDRGENERATOR ./QvantelCDRGenerator
    echo -e $GREEN"### Starting CDRGenerator container"$RESET
    docker run $DOCKER_OPTS \
    --restart=always \
    --net=host \
    --name cdrgenerator \
    -d $CDRGENERATOR
}

function dbconnector {
	# DBConnector container
    echo -e $YELLOW"### Cleaning DBConnector container"$RESET
    if [[ "$(docker ps | grep dbconnector)" ]]; then
        docker stop dbconnector
    fi
    if [[ "$(docker ps --all | grep dbconnector)" ]]; then
        docker rm dbconnector
    fi
    if [[ "$(docker images -q $DBCONNECTOR 2> /dev/null)" == "" ]]; then
        docker rmi $DBCONNECTOR
    fi
    echo -e $YELLOW"### Compiling DBConnector container"$RESET
    (cd ./QvantelDBConnector; sbt assembly)
    echo -e $YELLOW"### Building DBConnector container"$RESET
    docker build -t dbconnector ./QvantelDBConnector
    echo -e $GREEN"### Starting DBConnector container"$RESET
    # If run on a Mac, add moby host
    docker run $DOCKER_OPTS \
        --restart=always \
        --net=host \
        --name dbconnector \
        -d $DBCONNECTOR
}

function frontend {
    # Frontend container
    # Port: 3000
    if [ ! "$(docker ps --all | grep frontend)" ]; then
        echo -e $YELLOW"### Creating frontend container"$RESET
        docker run --name frontend \
            --restart=always \
            -p 3000:3000 \
            -v $GRAFANA_VOLUME_TARGET:/var/lib/grafana \
            -d $GRAFANA
    else
        echo -e $GREEN"### Restarting frontend container"$RESET
        docker restart frontend
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
    docker stop "$1"
    echo -e $RED"Removing $1"$RESET
    docker rm "$1"
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
            "dbc"|"dbconncetor")
                dbconnector
            ;;
            "frontend")
                frontend
            ;;
            *)
                load_order
            ;;
         esac
    ;;
    "stop")
        case "$2"
        in
            "cass"|"cassandra")
                stop_container cassandra
            ;;
            "cdr"|"cdrgenerator")
                stop_container cdrgenerator
            ;;
            "graphite")
                stop_container graphite
            ;;
            "dbc"|"dbconncetor")
                stop_container dbconnector
            ;;
            "frontend")
                stop_container frontend
            ;;
            *)
                echo -e $RED"Stopping containers"$RESET
                docker stop cassandra graphite backend cdrgenerator dbconnector frontend > /dev/null
            ;;
        esac
    ;;
    "clean")
        case "$2"
        in
            "cass"|"cassandra")
                clean_container cassandra
            ;;
            "cdr"|"cdrgenerator")
                clean_container cdrgenerator
            ;;
            "graphite")
                clean_container graphite
            ;;
            "dbc"|"dbconncetor")
                clean_container dbconnector
            ;;
            "frontend")
                clean_container frontend
            ;;
            *)
                echo -e $RED"Stopping containers"$RESET
                docker stop cassandra graphite backend cdrgenerator dbconnector frontend > /dev/null
                echo -e $RED"Removing containers"$RESET
                docker rm cassandra graphite backend cdrgenerator dbconnector frontend > /dev/null
            ;;
        esac
    ;;
    "help"|*)
        echo -e $usage
    ;;

esac

duration=$(( SECONDS - start ))
echo -e $CYAN"< Execution took $duration seconds >"$RESET
