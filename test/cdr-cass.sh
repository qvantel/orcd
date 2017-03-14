#!/bin/sh

# Command depencency checks

# Names, paths, configuration.
cass_container_name=$1
repo="QvantelCDRGenerator"
app_conf_path="${repo}/src/main/resources/application.conf"
batch_limit="gen\.batch\.limit"
batch_size_limit="gen\.cassandra\.element\.batch\.size"
cassandra_port="cassandra\.port"
temp_cassandra_result_file="out"

# Integration specific config
# match "gen.batch.limit=number" and force number to be 1
contents=$(cat "$app_conf_path")
sed -i "s#${batch_limit}\ *\=\ *\-*[0-9]*#${batch_limit}\=1#g" "$app_conf_path"

# match "gen.cassandra.element.batch.size=number" and force number to be 1
sed -i "s#${batch_size_limit}\ *\=\ *\-*[0-9]*#${batch_size_limit}\=1#g" "$app_conf_path"

# match "cassandra.port" and force number to be "9043"
sed -i "s#${cassandra_port}\ *\=\ *\"[0-9]*\"#${cassandra_port}\=\"9043\"#g" "$app_conf_path"

# run
cd "$repo"
sbt run
cd ../

# now look in cassandra and see if there is a record.
# Use heredoc to send in the use and select statements which will be stored
# in the file $temp_cassandra_result_file.
docker exec -i "$cass_container_name" cqlsh << EOF > "$temp_cassandra_result_file"
use qvantel;
select count(*) from call;
select count(*) from product;
EOF

# Read from file and grep for rows.
has_records=$(cat out | grep -oP '\s+[0-9]+')
# has_records is now a list, since we have run 2 queries(selext x2)

# use head and tail to get the first and last.
has_records_call=$(echo "$has_records" | head -n+1)
has_records_product=$(echo "$has_records" | tail -n+1)
# Should now be ones in both.

# cleanup
if [ -f "$temp_cassandra_result_file" ]
then
    echo "Removed temp file"
    rm out
fi

# Exit codes
if  [ $has_records -eq 1 ] &&
    [ $has_records_call -eq 1 ] &&
    [ $has_records_product -eq 1 ]
then
    echo "[success]"
else
    echo "[no success]"
fi
