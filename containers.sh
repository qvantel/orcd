CASSANDRA_VERSION="3.9"
GRAPHITE_VERSION="0.9.15"

 # define main 

function main { 

args=$1

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
				docker run --name cassandra -d cassandra:"$CASSANDRA_VERSION"
			;;
			"graphite")
				echo "Start graphite"
				docker run --name graphite -d graphite:"$GRAPHITE_VERSION"
			;;
			"rest")
				echo "Start rest"
			;;
			"app")
				echo "Start app"
			;;
			"all")
				echo "Start all"
			;;
			*)
				echo -e "Usage: \n start	cassandra\n	graphite\n	rest\n	app\n	all"
			;;
			
		esac
	;;
	"stop")
		echo "stop"
	;;
	"help"|*)
		echo -e "Commands:\nStatus\nStart\nStop\nHelp"
	;;

esac
}

# Call main function
main "$@"
