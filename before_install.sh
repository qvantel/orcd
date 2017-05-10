#!/bin/bash

test -f "$(which docker )" || { echo "Docker not installed"; exit 1; }
test -f "$(which npm)" || { echo "NPM not installed"; exit 1; }
test -f "$(which node)" || { echo "Node not installed";
    node_path=$(which nodejs)
    test -f "$node_path" && echo "Please symlink $node_path to $(dirname $node_path)/node";
    exit 1; }
test -f "$(which md5sum )" || { echo "md5sum not installed"; exit 1; }
test -f "$(which wget )" || { echo "wget not installed"; exit 1; }
test -f "$(which java )" || { echo "java not installed"; exit 1; }
test -f "$(which sbt )" || { echo "sbt not installed"; exit 1; }
