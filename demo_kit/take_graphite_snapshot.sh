#!/bin/sh

GRAPHITE_CONTAINER="graphite"
GRAPHITE_DEMO_PORT=2000

# Extract data from whisper into a tar file
# Note: backup.tar is around 2.7G
docker run --rm --volumes-from $GRAPHITE_CONTAINER -v $(pwd):/backup ubuntu tar cvf /backup/demo_kit.tar /opt/graphite/storage/whisper

