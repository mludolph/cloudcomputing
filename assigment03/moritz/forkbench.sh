#!/bin/bash

iperf3 --server &>/dev/null &
export IPERF3_HOST=$(ip route get 1 | awk '{print $7;exit}')

runtime=10
startTime=$(date +%s)
elapsedTime=0
count=0
total=0
while [ $elapsedTime -lt $runtime  ]
do
	fork=$(2>/dev/null ./forkbench 0 4096)
    total=$(echo "$total+$fork" | bc)
    currentTime=$(date +%s)
    elapsedTime=$(($currentTime-$startTime))
    count=$(($count+1))
done

# calculate average forks per seccond using bc 
fork=$(echo "scale=2;$total/$count" | bc)

uplink=$(iperf3 --client $IPERF3_HOST -f m -i 0 -t $runtime --parallel 5 -4 | grep '\[SUM\]' | awk 'NR==1{print $6; exit}')

echo "$fork,$uplink"

