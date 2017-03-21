#!/bin/bash
test -z "$(which docker >/dev/null)" || { echo "Docker command not available"; exit 1; }
test -z "$(which sed >/dev/null)" || { echo "Sed not available"; exit 1; }
test -z "$(which grep >/dev/null)" || { echo "Grep not available"; exit 1; }

# This integration test relies on a docker image with the name cassandra
# Is available. If not, exit 1
test -n "$(docker images | grep 'cassandra')" || { echo "Cassandra image not found.)"; exit 1; }

schema_file="/schema.cql"
container_name="int_cassandra"
cass_port="9043"


function provision_cass_container {
    # Provision a cassandra container.
    if [ -n "$(docker images | grep 'cassandra')" ]
    then
        if [ -n "$(docker ps -a | grep $container_name)" ]
        then
            docker stop  "$container_name"
            docker rm  "$container_name"
        fi

        docker run --name "$container_name" -p 9043:9042 -d cassandra
    fi
}

function deallocate_cass_container {
    # And we're back, now clean up the container
    echo "Removing container"
    docker stop "$container_name"
    docker rm "$container_name"
}

provision_cass_container

# Wait until cqlsh is up and running
echo "Waiting for cqlsh to be up"
while [ -n "$(docker exec -it "$container_name" cqlsh -e exit 2>&1 | grep '\(e\|E\)rror')" ]
do
    sleep 1
done

# Cassandra up, run cqlsh script.
echo "Running schema"
docker exec -it "$container_name" cqlsh -f "$schema_file"


# It's up!
# Run integration test
echo "Running integration test"
int_test=$(./cdr-cass.sh "$container_name" 2>&1)
echo "Integration test done"

# Test is done
deallocate_cass_container

# Finally, report back
if [ -n "$(echo $int_test | grep '[SUCCESS]')" ]
then
    echo "Integration test successful"
    exit 0
else
    echo "Interation test failed"
    cat "$int_test"
    exit 1
fi
