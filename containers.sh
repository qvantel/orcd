#!/bin/bash

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
RESET=$(tput sgr0)

# Cassandra
CASSANDRA_VERSION="3.9"
CASSANDRA=cassandra:$CASSANDRA_VERSION

# Graphite
GRAPHITE_VERSION="0.9.15"
GRAPHITE=nickstenning/graphite:$GRAPHITE_VERSION

# Backend
BACKEND_VERSION="latest"
BACKEND=backend:$BACKEND_VERSION

# Grafana
GRAFANA_VERSION="4.1.1"
GRAFANA=grafana/grafana:$GRAFANA_VERSION

usage="Usage: [start|stop|clean|help]"

GRAFANA_VOLUME_TARGET=$HOME/grafana
CASSANDRA_VOLUME_TARGET=$HOME/cassandra


case "$1"
in
    "start")
        # Cassandra container
        # Port: 9042
        if [ ! "$(docker ps --all | grep cassandra)" ]; then
            echo -e $YELLOW"### Creating cassandra container"$RESET
            docker run \
                --restart=always \
                --name cassandra \
                -p 9042:9042 \
                -d cassandra
        else
            echo -e $GREEN"### Restarting cassandra container"$RESET
            docker restart cassandra
        fi

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

        # Backend container
        # Port: 8080
        echo -e $YELLOW"### Cleaning backend container"$RESET
        if [[ "$(docker ps | grep backend)" ]]; then
            docker stop backend
        fi
        if [[ "$(docker ps --all | grep backend)" ]]; then
            docker rm backend
        fi
        if [[ "$(docker images -q $BACKEND 2> /dev/null)" == "" ]]; then
            docker rmi $BACKEND
        fi
        echo -e $YELLOW"### Compiling backend container"$RESET
        (cd ./QvantelBackend; sbt assembly)
        echo -e $YELLOW"### Building backend container"$RESET
        docker build -t backend ./QvantelBackend
        echo -e $GREEN"### Starting backend container"$RESET
        docker run \
            --restart=always \
            --name backend \
            -p 8080:8080 \
            -d $BACKEND

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
    ;;
    "stop")
        echo -e $RED"Stopping containers"$RESET
        docker stop cassandra graphite backend frontend > /dev/null
    ;;
    "clean")
        echo -e $RED"Stopping containers"$RESET
        docker stop cassandra graphite backend frontend > /dev/null
        echo -e $RED"Removing containers"$RESET
        docker rm cassandra graphite backend frontend > /dev/null
    ;;
    "help"|*)
        echo -e $usage
    ;;

esac
