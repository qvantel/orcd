#!/bin/bash
# Command depencency checks
# Names, paths, configuration.
# Incoming container name from argument
cass_container_name=$1

# Paths
repo="QvantelCDRGenerator"
app_conf_path="src/main/resources/application.conf"

# What in config file needs to be updated(for intgr. test)
batch_limit="batch\.limit"
batch_size_limit="cassandra\.element\.batch\.size"
cassandra_port="port"
cassandra_it_port=9043
cassandra_keyspace="qvantel"
cassandra_cdr_table_name="cdr"

jar_directory="target/scala-2.11/CDRGenerator.jar"

# What file to save result of docker/cassandra query
temp_cassandra_result_file="out"

# CDR generator timeout. Cancel command if exceeds x seconds.
timeout=45

# Checks, exit if param empty
[ -n "$1" ] || { echo "empty params[no success]"; exit 1; }

# Same, except if not a docker container.
[ -z "$(docker ps | grep $1)" ] && { echo "The string the argument '$1' provided is not a running container. [no success]"; exit 1; }

# Use the stack to navigate to the submodule
pushd "../$repo" 2>&1 1>/dev/null

# If there is no file, fail
[ -f "$app_conf_path" ] || { echo "No such file: $app_conf_path [no success]"; exit 1; }

# Warn if has already edited.
[ -z "$(git diff $app_conf_path)" ] || { echo "It appears that the $app_conf_path has already been edited(Checked with git diff). Exiting the test. [no success]"; exit 1; }

# Integration specific config
# match "gen.batch.limit=number" and force number to be 1
sed -i "s#${batch_limit}\ *\=\ *\-*[0-9]*#${batch_limit}\=1#g" "$app_conf_path"

# match "gen.cassandra.element.batch.size=number" and force number to be 1
sed -i "s#${batch_size_limit}\ *\=\ *\-*[0-9]*#${batch_size_limit}\=1#g" "$app_conf_path"

# match "cassandra.port" and force number to be "9043"
sed -i "s#${cassandra_port}\ *\=\ *\"[0-9]*\"#${cassandra_port}\=\"${cassandra_it_port}\"#g" "$app_conf_path"

# Verify that our config file is what we want.
grep -q "${batch_limit}=1" "$app_conf_path" 2>&1 && echo -n "" || { echo "Failed to set batch limit [no success]"; exit 1; }
grep -q "${batch_size_limit}=1" "$app_conf_path" && echo -n "" ||  { echo "Failed to set batch size limit [no success]"; exit 1; }
grep -q "${cassandra_port}=\"${cassandra_it_port}\"" "$app_conf_path" && echo -n "" || { echo "Failed to set cassandra port [no success]"; exit 1; }

# Compile CDRGenerator.jar if it doesn't exist.
[ ! -f "$jar_directory" ] && sbt assembly

# Finally, run the jar.
# Run with timeout
timeout $timeout java -Dnetty.epoll.enabled=false -Dconfig.file=$app_conf_path -Dtrends.dir=src/main/resoucers/trends/ -jar "$jar_directory"

# Return the config file as it was.
echo "Checking out $app_conf_path"
git checkout $app_conf_path

# Pop back to original directory
popd 2>&1 1>/dev/null

# now look in cassandra and see if there is a record.
# Use heredoc to send in the use and select statements which will be stored
# in the file $temp_cassandra_result_file.

docker exec -i "$cass_container_name" cqlsh << EOF > "$temp_cassandra_result_file"
use $cassandra_keyspace;
select count(*) from $cassandra_cdr_table_name;
EOF
# If the query was successful, there should now be a file.
[ -f $temp_cassandra_result_file ] || { echo "No cassandra result file[no success]"; exit 1; }

# Read from file and grep for rows.
has_records=$(cat "$temp_cassandra_result_file" | grep -oP '\s+[0-9]+')

# use head and tail to get the first and last.
has_records_cdr=$(echo "$has_records" | head -n+1)
#
# cleanup
if [ -f "$temp_cassandra_result_file" ]
then
   echo "Removed temp file"
   rm "$temp_cassandra_result_file"
fi

# Exit codes
if [ $has_records_cdr -eq 1 ]
then
   echo '[success]'
else
   echo '[no success]'
fi
