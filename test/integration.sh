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
dbc_app_conf_path="src/main/resources/application.conf"
dbc_container_image="hopsoft/graphite-statsd"
dbc_container_name="dbc_test_container"
cass_port="9043"
dbc_graph_port="2025"

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

function provision_dbc_container {

    #provision container
    if [ -n "$(docker images | grep $dbc_container_image)" ]
    then 
        if [ -n "$(docker ps -a | grep $dbc_container_name)" ]
            then
             deallocat_dbc_container
        fi
        
        echo "running $dbc_container_name"
        #change the port for the graphite to a new port in config file 
        sed -i "s#c.port = [0-9]*#c.port = $cass_port#g" $dbc_app_conf_path 
        sed -i "s#g.port = [0-9]*#g.port = $dbc_graph_port#g" $dbc_app_conf_path
        # run docker to create new container with new port and  
        docker run \
        --name $dbc_container_name \
        -p 2025-2026:2003-2004 \
        -p 2090:80 \
        -p 8125:8125/udp \
        -p 8126:8126 \
        -p 2027-2028:2023-2024 \
        -d hopsoft/graphite-statsd:latest
    fi
}

function deallocat_dbc_container {

    # deallocate the dbc container
    docker stop "$dbc_container_name"
    echo "dbc connector container stopped"
    docker rm "$dbc_container_name"
    echo "dbc connector removed"
}

function deallocate_cass_container {
    # And we're back, now clean up the container
    docker stop  "$container_name" 2>&1 1>/dev/null && echo "Stopping $container_name"
    docker rm  "$container_name" 2>&1 1>/dev/null && echo "removing $container_name"
}

provision_cass_container
pushd ../QvantelDBConnector/
provision_dbc_container
popd

# Wait until cqlsh is up and running
echo "Waiting for cqlsh to be up"
while [ -n "$(docker exec -it "$container_name" cqlsh -e exit 2>&1 | grep '\(e\|E\)rror')" ]
do
    sleep 1
done

# Cassandra up, run cqlsh script.
echo "Running schema"
docker exec -it "$container_name" cqlsh -f "$schema_file"

# Cqlsh is up!
# Run integration test
echo "Running cdr_cassandra integration test"
int_test=$(./cdr_cass_integration_test.sh "cassandra_qvantel" 2>&1)
code=$?
echo "cdr_cassandra Integration test done"

#run dbconnector integration test
echo "running dbconnector integration test"
dbc_inte_test=$(./dbcIntegrationTest.sh 2>&1)
result=$?
echo "dbconnector integration test done"

# Test is done
#remove cassandra container
deallocate_cass_container
deallocat_dbc_container

# Finally, report back
if [ -n "$(echo $int_test | grep '[SUCCESS]')" ] && [ $code -eq 0 ]
then
    echo "cdr_cass Integration test successful"
    
else
    echo "cdr_cass Integration test failed"
    echo "$int_test"
    exit 1
fi

# Finally, report back dbconnector
if [ -n "$(echo $dbc_inte_test | grep '[-success-]')" ] && [ $result -eq 0 ]
then
    echo "dbConnector Integration test successful"
    exit 0
else
    echo "dbConnector Integration test failed"
    exit 1
fi
