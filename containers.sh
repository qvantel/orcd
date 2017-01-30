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

# Grafana
GRAFANA_VERSION="4.1.1"
GRAFANA=grafana/grafana:$GRAFANA_VERSION

usage="Usage: [start|stop|help]"

case "$1"
in
	"start")
		# Cassandra container
		docker run --name cassandra -d $CASSANDRA

		# Graphite container
		docker run --name graphite -d $GRAPHITE

		# Backend container
		(cd ./QvantelBackend; sbt assembly)
		if [[ "$(docker images -q $BACKEND 2> /dev/null)" == "" ]]; then
			docker rmi $BACKEND
		fi
		docker build -t backend ./QvantelBackend
		docker run --name backend -p 8080:8080 -d $BACKEND

		# Frontend container
		if [[ $OSTYPE == *"darwin"* ]]; then
			GRAFANA_VOLUME_TARGET=$HOME/grafana
		else
			GRAFANA_VOLUME_TARGET=/var/lib/grafana
		fi
		docker run -d --name frontend \
			-p 3000:3000 \
			-v $GRAFANA_VOLUME_TARGET:/var/lib/grafana \
			$GRAFANA
	;;
	"stop")
		echo "Stopping containers"
		docker stop cassandra graphite backend frontend > /dev/null
		echo "Removing containers"
		docker rm cassandra graphite backend frontend > /dev/null
	;;
	"help"|*)
		echo -e $usage
	;;

esac
