#!/bin/bash

DBCrepo="QvantelDBConnector"
app_conf_path="src/main/resources/application.conf"
cass_container_name="cassandra_qvantel"
# What in config file needs to be updated(for intgr. test)
batch_limit="batch\.limit"
batch_size_limit="cassandra\.element\.batch\.size"
cassandra_port="port"
cassandra_it_port=9042
cassandra_keyspace="qvantel"
cassandra_cdr_table_name="cdr"
limit="limit"

jar_directory="target/scala-2.11/DBConnector.jar"

# What file to save result of docker/cassandra query
temp_cass_service_file="service"
temp_cass_createdAt_file="createdAt"
temp_cass_eventDetails_file="eventsDetails"
temp_cass_usedServiceUnit_file="usedServiceUnet"

# --> Run cdr-cassandra integration test
echo "Running cdr--> cassandra integration test!"
#int_test=$(./cdr_cass_integration_test.sh "cassandra_qvantel" 2>&1)
#code=$?
echo "cdr-->cassandra Integration test done!"

# match "limit=number" and force number to be 1
echo $limit
pushd ../QvantelDBConnector/
sed -i "s#${limit}\ *\=\ *\-*[0-9]*#${limit}\=1#g" "$app_conf_path"

echo "run dbconnector using sbt run"
sbt run
echo "now we are running sbt to start the dbconnector."


#popd
#pwd


#rm "$temp_cass_result_file"
echo "now deleting file...."
