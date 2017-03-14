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
CASSANDRA_NAME="cassandra_qvantel"
CASSANDRA_VERSION="latest"
CASSANDRA=$CASSANDRA_NAME:$CASSANDRA_VERSION
CASSANDRA_PORT=9042

# Graphite
GRAPHITE_NAME="graphite"
GRAPHITE_VERSION="0.9.15"
GRAPHITE=nickstenning/graphite:$GRAPHITE_VERSION

# Backend
BACKEND_NAME="backend"
BACKEND_VERSION="latest"
BACKEND=$BACKEND_NAME:$BACKEND_VERSION

# CDRGenerator
CDRGENERATOR_NAME="cdrgenerator"
CDRGENERATOR_VERSION="latest"
CDRGENERATOR=$CDRGENERATOR_NAME:$CDRGENERATOR_VERSION


# DBConnector
DBCONNECTOR_NAME="dbconnector"
DBCONNECTOR_VERSION="latest"
DBCONNECTOR=$DBCONNECTOR_NAME:$DBCONNECTOR_VERSION

# Frontend
FRONTEND_NAME="frontend"
FRONTEND_VERSION="latest"
FRONTEND=$FRONTEND_NAME:$FRONTEND_VERSION

usage="Usage: [start|stop|clean|help]
              start [(cass|cassandra)|(cdr|cdrgenerator)|graphite|(dbc|dbconnector)|frontend|"

GRAFANA_VOLUME_TARGET=$HOME/grafana
CASSANDRA_VOLUME_TARGET=$HOME/cassandra

cass_build=0
function cassandra {
    # Cassandra container
    # Port: 9042
    if [ ! "$(docker ps --all | grep $CASSANDRA_NAME)" ]; then
        echo -e $YELLOW"### Creating cassandra container"$RESET
        docker build -t $CASSANDRA_NAME ./Cassandra
        docker run \
            --restart=always \
            --name $CASSANDRA_NAME \
            -p $CASSANDRA_PORT:$CASSANDRA_PORT \
            -d $CASSANDRA
        cass_build=1
    else
        echo -e $GREEN"### Restarting cassandra container"$RESET
        docker restart $CASSANDRA_NAME
    fi
}

function graphite {
        # Graphite container
        # Ports: Receive=2003, WebApp=2000
        if [ ! "$(docker ps --all | grep $GRAPHITE_NAME)" ]; then
            echo -e $YELLOW"### Creating graphite container"$RESET
            docker run \
                --restart=always \
                --name $GRAPHITE_NAME \
                -p 2003:2003 -p 2000:80 \
                -d $GRAPHITE
        else
            echo -e $GREEN"### Restarting graphite container"$RESET
            docker restart $GRAPHITE_NAME
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
    if [ -n "$(docker ps | grep $CASSANDRA_NAME)" ]
    then
        echo "Waiting for port to open"
        while [ -n "$(docker exec -it $CASSANDRA_NAME cqlsh -e exit 2>&1 | grep '\(e\|E\)rror')" ]
        do
            sleep 0.1
        done
        echo "Cqlsh is up and running"
        if [ "$cass_build" -eq 1 ]; then
            echo "Running schema"
            docker exec -it $CASSANDRA_NAME cqlsh -f /schema.cql
            cass_build=0
        fi
    fi

    if [[ "$(docker ps --all | grep $CDRGENERATOR_NAME)" ]]; then
    	echo -e $YELLOW"### Cleaning CDRGenerator container"$RESET
	clean_container $CDRGENERATOR_NAME
    fi
    if [[ "$(docker images -q $CDRGENERATOR 2> /dev/null)" == "" ]]; then
        docker rmi $CDRGENERATOR_NAME
    fi
    echo -e $YELLOW"### Compiling CDRGenerator container"$RESET
    (cd ./QvantelCDRGenerator; sbt assembly)
    
    echo -e $YELLOW"### Building CDRGenerator container"$RESET
    docker build -t $CDRGENERATOR ./QvantelCDRGenerator
    
    echo -e $GREEN"### Starting CDRGenerator container"$RESET
    docker run $DOCKER_OPTS \
        --restart=always \
        --net=host \
        --name $CDRGENERATOR_NAME \
        -d $CDRGENERATOR
}

function dbconnector {
    # DBConnector container
    if [[ "$(docker ps --all | grep $DBCONNECTOR_NAME)" ]]; then
        echo -e $YELLOW"### Cleaning DBConnector container"$RESET
	clean_container $DBCONNECTOR_NAME
    fi
    if [[ "$(docker images -q $DBCONNECTOR 2> /dev/null)" == "" ]]; then
        docker rmi $DBCONNECTOR
    fi
    
    echo -e $YELLOW"### Compiling DBConnector container"$RESET
    (cd ./QvantelDBConnector; sbt assembly)
    
    echo -e $YELLOW"### Building DBConnector container"$RESET
    docker build -t $DBCONNECTOR_NAME ./QvantelDBConnector
    
    echo -e $GREEN"### Starting DBConnector container"$RESET
    docker run $DOCKER_OPTS \
        --restart=always \
        --net=host \
        --name $DBCONNECTOR_NAME \
        -d $DBCONNECTOR_NAME
}

function frontend {
    # Frontend container
    # Port: 3000
    if [[ "$(docker ps --all | grep $FRONTEND_NAME)" ]]; then
        echo -e $YELLOW"### Cleaning QvantelFrontend container"$RESET
	clean_container $FRONTEND_NAME
    fi

    echo -e $YELLOW"### Creating frontend container"$RESET
    npm --prefix ./QvantelFrontend run build
    docker build -t $FRONTEND_NAME ./QvantelFrontend

    echo -e $GREEN"### Starting QvantelFrontend container"$RESET
    docker run --name $FRONTEND_NAME \
        --restart=always \
        -p 3000:3000 \
        -d $FRONTEND_NAME
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
                stop_container $CASSANDRA_NAME
            ;;
            "cdr"|"cdrgenerator")
                stop_container $CDRGENERATOR_NAME
            ;;
            "graphite")
                stop_container $GRAPHITE_NAME
            ;;
            "dbc"|"dbconnector")
                stop_container $DBCONNECTOR_NAME
            ;;
            "backend")
                stop_container $BACKEND_NAME
            ;;
            "frontend")
                stop_container $FRONTEND_NAME
            ;;
            *)
                if [ -z "$2" ]; then
                    echo -e $RED"Stopping containers"$RESET
                    docker stop $CASSANDRA_NAME $GRAPHITE_NAME $CDRGENERATOR_NAME $DBCONNECTOR_NAME $FRONTEND_NAME > /dev/null
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
                clean_container $CASSANDRA_NAME
            ;;
            "cdr"|"cdrgenerator")
                clean_container $CDRGENERATOR_NAME
            ;;
            "graphite")
                clean_container $GRAPHITE_NAME
            ;;
            "dbc"|"dbconnector")
                clean_container $DBCONNECTOR_NAME
            ;;
            "backend")
                clean_container $BACKEND_NAME
            ;;
            "frontend")
                clean_container $FRONTEND_NAME
            ;;
            *)
                if [ -z "$2" ]; then
                    echo -e $RED"Stopping containers"$RESET
                    docker stop $CASSANDRA_NAME $GRAPHITE_NAME $CDRGENERATOR_NAME $DBCONNECTOR_NAME $FRONTEND_NAME > /dev/null
                    echo -e $RED"Removing containers"$RESET
                    docker rm $CASSANDRA_NAME $GRAPHITE_NAME $CDRGENERATOR_NAME $DBCONNECTOR_NAME $FRONTEND_NAME > /dev/null
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
