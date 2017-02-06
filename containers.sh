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

GRAFANA_VOLUME_TARGET=$HOME/grafana
CASSANDRA_VOLUME_TARGET=$HOME/cassandra


case "$1"
in
	"start")
		# Cassandra container
		# Port: 9042
		docker run \
			--name cassandra \
			-p 9042:9042 \
			-d cassandra

		# Graphite container
		# Ports: Receive=2003, WebApp=2000
		docker run \
			--name graphite \
			-p 2003:2003 -p 2000:80 \
			-d $GRAPHITE

		# Backend container
		# Port: 8080
		(cd ./QvantelBackend; sbt assembly)
		if [[ "$(docker images -q $BACKEND 2> /dev/null)" == "" ]]; then
			docker rmi $BACKEND
		fi
		docker build -t backend ./QvantelBackend
		docker run \
			--name backend \
			-p 8080:8080 \
			-d $BACKEND

		# Frontend container
		# Port: 3000
		docker run --name frontend \
			-p 3000:3000 \
			-v $GRAFANA_VOLUME_TARGET:/var/lib/grafana \
			-d $GRAFANA
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
