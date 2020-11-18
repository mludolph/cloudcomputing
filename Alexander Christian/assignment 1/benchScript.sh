#!/bin/bash
clear
if ! -f "output.txt"; then
touch output.txt
fi
date +%s | tr -d "\n"
echo -n ","
sysbench --test=cpu --time=10 run | grep "events per second:" |  cut -d ":" -f2 | cut -d " " -f3 | tr -d "\n"
echo -n ","
sysbench --test=memory --time=10 --memory-block-size=4KB --memory-total-size=100TB run | grep "MiB transferred" | cut -d "(" -f2 | cut -d " " -f1 | tr -d "\n"
echo -n ","
sysbench --test=fileio --file-total-size=1G --file-num=1 prepare > /dev/null
sysbench --test=fileio  --file-num=1 --file-total-size=1GB --file-test-mode=rndrd --file-async-backlog=direct --time=10 run | grep "read, MiB/s:" | cut -d " " -f24 | tr -d "\n"
echo -n ","
sysbench --test=fileio  --file-num=1 --file-total-size=1GB --file-test-mode=seqrd --file-async-backlog=direct --time=10 run | grep "read, MiB/s:" | cut -d " " -f24
