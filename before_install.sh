#!/bin/bash

test -f "$(which docker )" || { echo "Docker not installed"; exit 1; }
test -f "$(which npm)" || { echo "NPM not installed"; exit 1; }
test -f "$(which node)" || { echo "Node not installed";
    node_path=$(which nodejs)
    test -f "$(which nodejs)" && echo "Please symlink $(which nodejs) to $(dirname $k)/node";
    exit 1; }
test -f "$(which md5sum )" || { echo "md5sum not installed"; exit 1; }
test -f "$(which wget )" || { echo "wget not installed"; exit 1; }
test -f "$(which java )" || { echo "java not installed"; exit 1; }
test -f "$(which sbt )" || { echo "sbt not installed"; exit 1; }
