#!/bin/bash

SERVER=127.0.0.1;
PORT=2003;
GB_DIVIDER=1000;
while true; do

  # CPU in %
  CPU=$[100-$(vmstat 1 2|tail -1|awk '{print $15}')]

  # used memory in MB
  USED_MEM=$(free -m | awk '{print $3}' | sed -n 2p)
  # converting used memory in MB into gigabytes
  USED_MEM_GB=$(bc <<< "scale=2 ; $USED_MEM / $GB_DIVIDER")


  # Free memory in MB
  FREE_MEM=$(free -m | awk '{print $4}' | sed -n 2p)
  # converting free memory in MB into gigabytes
  FREE_MEM_GB=$(bc <<< "scale=2 ; $FREE_MEM / $GB_DIVIDER")


  #  Available space in disk in MB
  AVAILABLE_SPACE=$(df -m --total | tail -1 | awk '{print $4}')
  # converting available space in MB into gigabytes
  AVAILABLE_SPACE_GB=$(bc <<< "scale=2 ; $AVAILABLE_SPACE / $GB_DIVIDER")


  echo "cassandra.memory.used $USED_MEM_GB `date +%s`" |  nc ${SERVER} ${PORT}
  echo "cassandra.cpu.usage ${CPU} `date +%s`" | nc ${SERVER} ${PORT}
  echo "cassandra.memory.free ${FREE_MEM_GB} `date +%s`" | nc ${SERVER} ${PORT}
  echo "cassandra.disk.available ${AVAILABLE_SPACE_GB} `date +%s`" | nc ${SERVER} ${PORT}

  sleep 2;
done
