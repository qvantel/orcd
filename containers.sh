#!/bin/bash

# Cassandra
CASSANDRA_VERSION="3.9"
CASSANDRA=cassandra:$CASSANDRA_VERSION

# Graphite
GRAPHITE_VERSION="0.9.15"
GRAPHITE=nickstenning/graphite:$GRAPHITE_VERSION

# Backend
BACKEND_VERSION="latest"
BACKEND=backend:$BACKEND_VERSION

usage="Usage: [start|stop|help]"

case "$1"
in
	"start")
		echo "NOTICE: All docker containers are not yet implemented"
		docker run --name cassandra -d $CASSANDRA
		docker run --name graphite -d $GRAPHITE

		(cd ./QvantelBackend; sbt assembly)
		if [[ "$(docker images -q $BACKEND 2> /dev/null)" == "" ]]; then
			docker rmi $BACKEND
		fi
		docker build -t backend ./QvantelBackend
		docker run --name backend -p 8080:8080 -d $BACKEND
	;;
	"stop")
		echo "Stopping containers"
		docker stop cassandra graphite backend > /dev/null
		echo "Removing containers"
		docker rm cassandra graphite backend > /dev/null
	;;
	"help"|*)
		echo -e $usage
	;;

esac
