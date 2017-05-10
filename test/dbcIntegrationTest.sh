#!/bin/bash

app_conf_path="src/main/resources/application.conf"
limit="processing.maximumProcessingLimit"
tempGraphiteFile="tempGraphiteData.txt"

#match "limit=number" and force number to be 1
pushd ../QvantelDBConnector/
sed -i "s#${limit}\ *\=\ *\-*[0-9]*#${limit}\ = 5#g" "$app_conf_path"

# now running the dbconnector
echo "running dbconnector using sbt run"
sbt run

# now change the app.config file to its origin
sed -i "s#${limit}\ *\=\ *\-*[0-9]*#${limit}\ = -1#g" "$app_conf_path"

# back to the directory you were in at the beginning
popd 

#now run curl to check if the data is at graphite. in this case we are looking for "callplanNormal"
curl '127.0.0.1:2090/render?target=qvantel.product.voice.CallPlanNormal&format=json' -o $tempGraphiteFile

#check if the file contain data using grep
if grep -Fxq "[]" $tempGraphiteFile
then
#there are no records in this file
echo "the dbconnector integration test failed!"
echo "[-failed-]"
else
#there are records in this file
echo "dbconnector integration test is done and successfull"
echo "[-success-]"
fi

# reset the "application.config" file to its origin values
pushd ../QvantelDBConnector/
#change the port for the graphite to a new port in config file 
sed -i "s#c.port = [0-9]*#c.port = 9042#g" "$app_conf_path"
sed -i "s#g.port = [0-9]*#g.port = 2003#g" "$app_conf_path"
popd

#now remove the temp file 
rm -f $tempGraphiteFile
