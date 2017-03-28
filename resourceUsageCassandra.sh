#!/bin/bash

SERVER=127.0.0.1;
PORT=2003;

while true; do
  
  # CPU in %
  CPU=$[100-$(vmstat 1 2|tail -1|awk '{print $15}')]
	
  # used memory in MB 
  USED_MEM=$(free -m | awk '{print $3}' | sed -n 2p)

  # Free memory in MB
  FREE_MEM=$(free -m | awk '{print $4}' | sed -n 2p)

  #  Available space in disk in MB
  AVAILABLE_SPACE=$(df -m --total | tail -1 | awk '{print $4}')
  
  echo "cassandra.memory.used ${USED_MEM} `date +%s`" | nc ${SERVER} ${PORT}
  echo "cassandra.cpu.usage ${CPU} `date +%s`" | nc ${SERVER} ${PORT}
  echo "cassandra.memory.free ${FREE_MEM} `date +%s`" | nc ${SERVER} ${PORT}
  echo "cassandra.disk.used ${AVAILABLE_SPACE} `date +%s`" | nc ${SERVER} ${PORT}

  sleep 2;
done
