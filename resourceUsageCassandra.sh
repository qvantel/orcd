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
  # total memory in MB
  TOTAL_MEM=$(free -m | awk '{print $2}' | sed -n 2p)
  # converting total memory in MB into gigabytes
  TOTAL_MEM_GB=$(bc <<< "scale=2 ; $TOTAL_MEM / $GB_DIVIDER")


  # Free memory in MB
  FREE_MEM=$(free -m | awk '{print $4}' | sed -n 2p)
  # converting free memory in MB into gigabytes
  FREE_MEM_GB=$(bc <<< "scale=2 ; $FREE_MEM / $GB_DIVIDER")


  #  Used space in disk in MB
  USED_SPACE=$(df -m --total | tail -1 | awk '{print $3}')
  # converting used space in MB into gigabytes
  USED_SPACE_GB=$(bc <<< "scale=2 ; $USED_SPACE / $GB_DIVIDER")
  #  Total space in disk in MB
  TOTAL_SPACE=$(df -m --total | tail -1 | awk '{print $2}')
  # total available space in MB into gigabytes
  TOTAL_SPACE_GB=$(bc <<< "scale=2 ; $TOTAL_SPACE / $GB_DIVIDER")

  echo "cassandra.cpu.usage ${CPU} `date +%s`" | nc ${SERVER} ${PORT}

  echo "cassandra.memory.used $USED_MEM_GB `date +%s`" |  nc ${SERVER} ${PORT}
  echo "cassandra.memory.free ${FREE_MEM_GB} `date +%s`" | nc ${SERVER} ${PORT}
  echo "cassandra.memory.total ${TOTAL_MEM_GB} `date +%s`" | nc ${SERVER} ${PORT}

  echo "cassandra.disk.used ${USED_SPACE_GB} `date +%s`" | nc ${SERVER} ${PORT}
  echo "cassandra.disk.total ${TOTAL_SPACE_GB} `date +%s`" | nc ${SERVER} ${PORT}

  #sleep 2;
done
