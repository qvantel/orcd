#!/bin/bash

# Cassandra
CASSANDRA_VERSION="3.9"
CASSANDRA=cassandra:$CASSANDRA_VERSION

# Graphite
GRAPHITE_VERSION="0.9.15"
GRAPHITE=nickstenning/graphite:$GRAPHITE_VERSION

containers="cassandra graphite"

# define main

function main { 

args=$1

usage="\
Usage: [status|start|stop] [CONTAINER|all]\n
\tContainers: $containers"

case "$args"  
in
	"status")
		echo "Status"
	;;
	"start")
		shift
		case "$1"
		in 
			"cassandra")
				echo "Start cassandra"
				docker run --name cassandra -d $CASSANDRA
			;;
			"graphite")
				echo "Start graphite"
				docker run --name graphite -d $GRAPHITE
			;;
			"rest")
				echo "Docker container for REST server not yet implemented"
			;;
			"app")
				echo "Docker container for webapp not yet implemented"
			;;
			"all")
				echo "NOTICE: All docker containers are not yet implemented, only starting: $containers"
				main start cassandra
				main start graphite
			;;
			*)
				echo $usage
			;;
			
		esac
	;;
	"stop")
		shift
		case "$1"
		in
			"all")
				echo "Stopping containers"
				docker stop $containers > /dev/null
				echo "Removing containers"
				docker rm $containers > /dev/null
			;;
			*)
				echo "$usage"
			;;
		esac
	;;
	"help"|*)
		echo -e $usage
	;;

esac
}

# Call main function
main "$@"
