#!/bin/sh

GRAPHITE_CONTAINER="graphite"
GRAPHITE_DEMO_PORT=2000

# Import whisper data into a docker volume 
docker run -v /opt/graphite/storage/whisper --name demostore ubuntu /bin/bash
docker run --rm --volumes-from demostore -v $(pwd):/backup ubuntu bash -c "tar xvf /backup/demo_kit.tar"

# Create graphite container using the demostore volume
docker run -d -p $GRAPHITE_DEMO_PORT:80 --volumes-from demostore --name demographite hopsoft/graphite-statsd

cd ..
./containers.sh start frontend

