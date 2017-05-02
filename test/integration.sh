#!/bin/bash
test -z "$(which docker >/dev/null)" || { echo "Docker not available"; exit 1; }
test -z "$(which sed >/dev/null)" || { echo "Sed not available"; exit 1; }
test -z "$(which grep >/dev/null)" || { echo "Grep not available"; exit 1; }
test -z "$(which pushd >/dev/null)" || { echo "Pushd not available"; exit 1; }
test -z "$(which git >/dev/null)" || { echo "Git not available"; exit 1; }

# This integration test relies on a docker image with the name cassandra
# Is available. If not, exit 1

schema_file="/schema.cql"
container_name="int_cassandra"
container_image_name="cassandra_qvantel"
cass_port="9043"

test -n "$(docker images | grep $container_image_name)" || { echo "Cassandra image not found.)"; exit 1; }

function provision_cass_container {
    # Provision a cassandra container.
    if [ -n "$(docker images | grep $container_image_name)" ]
    then
        if [ -n "$(docker ps -a | grep $container_name)" ]
        then
            deallocate_cass_container
        fi

        echo "Running $container_name"
        docker build -t "$container_image_name" ../Cassandra/
        docker run --name "$container_name" -p "$cass_port":9042 -d "$container_image_name"
    fi
}

function deallocate_cass_container {
    # And we're back, now clean up the container
    docker stop  "$container_name" 2>&1 1>/dev/null && echo "Stopping $container_name"
    docker rm  "$container_name" 2>&1 1>/dev/null && echo "Stopping $container_name"
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
int_test=$(./cdr_cass_integration_test.sh "cassandra_qvantel" 2>&1)
code=$?
echo "Integration test done"

# Test is done
deallocate_cass_container

# Finally, report back
if [ -n "$(echo $int_test | grep '[SUCCESS]')" ] && [ $code -eq 0 ]
then
    echo "Integration test successful"
    exit 0
else
    echo "Integration test failed"
    echo "$int_test"
    exit 1
fi
