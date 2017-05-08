#! /bin/sh

GRAPHITE_CONTAINER="graphite"
GRAPHITE_DEMO_PORT=2000


# Extract data from whisper into a tar file
# Note: backup.tar is around 2.7G
docker run --rm --volumes-from $GRAPHITE_CONTAINER -v $(pwd):/backup ubuntu tar cvf /backup/backup.tar /opt/graphite/storage/whisper

# Import whisper data into a docker volume 
docker run -v /opt/graphite/storage/whisper --name demostore ubuntu /bin/bash
docker run --rm --volumes-from demostore -v $(pwd):/backup ubuntu bash -c "tar xvf /backup/backup.tar"

# Create graphite container using the demostore volume
docker run -d -p $GRAPHITE_DEMO_PORT:80 --volumes-from demostore --name demographite hopsoft/graphite-statsd

