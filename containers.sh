#!/bin/bash

# Cassandra
CASSANDRA_VERSION="3.9"
CASSANDRA=cassandra:$CASSANDRA_VERSION

# Graphite
GRAPHITE_VERSION="0.9.15"
GRAPHITE=nickstenning/graphite:$GRAPHITE_VERSION


usage="Usage: [status|start|stop|help]"

case "$1"
in
	"status")
		echo "Not yet implemented"
	;;
	"start")
		echo "NOTICE: All docker containers are not yet implemented"
		docker run --name cassandra -d $CASSANDRA
		docker run --name graphite -d $GRAPHITE
	;;
	"stop")
		echo "Stopping containers"
		docker stop cassandra graphite > /dev/null
		echo "Removing containers"
		docker rm cassandra graphite > /dev/null
	;;
	"help"|*)
		echo -e $usage
	;;

esac
