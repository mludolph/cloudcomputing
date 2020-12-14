#!/bin/bash
# This script benchmarks CPU, memory and random/sequential disk access.
# Some debug output is written to stderr, and the final benchmark result is output on stdout as a single CSV-formatted line.

# Execute the sysbench tests for the given number of seconds
runtime=60

# Record the Unix timestamp before starting the benchmarks.
time=$(date +%s)

# Run the sysbench CPU test and extract the "events per second" line.
1>&2 echo "Running CPU test..."
cpu=$(sysbench --time=$runtime cpu run | grep "events per second" | awk '/ [0-9.]*$/{print $NF}')

# Run the sysbench memory test and extract the "transferred" line. Set large total memory size so the benchmark does not end prematurely.
1>&2 echo "Running memory test..."
mem=$(sysbench --time=$runtime --memory-block-size=4K --memory-total-size=100T memory run | grep -oP 'transferred \(\K[0-9\.]*')

# Prepare one file (1GB) for the disk benchmarks
1>&2 sysbench --file-total-size=1G --file-num=1 fileio prepare

# Run the sysbench sequential disk benchmark on the prepared file. Use the direct disk access flag. Extract the number of read MiB.
1>&2 echo "Running fileio sequential read test..."
diskSeq=$(sysbench --time=$runtime --file-test-mode=seqrd --file-total-size=1G --file-num=1 --file-extra-flags=direct fileio run | grep "read, MiB" | awk '/ [0-9.]*$/{print $NF}')

# Run the sysbench random access disk benchmark on the prepared file. Use the direct disk access flag. Extract the number of read MiB.
1>&2 echo "Running fileio random read test..."
diskRand=$(sysbench --time=$runtime --file-test-mode=rndrd --file-total-size=1G --file-num=1 --file-extra-flags=direct fileio run | grep "read, MiB" | awk '/ [0-9.]*$/{print $NF}')

# Run forkbench until 60 seconds elapsed
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

# connect to iperf3 server (specified by env variable) with the specified parameters (-f m: format in Mbit/s, 
# -i 0 no intermediate results, -t $runtime: run for $runtime seconds, --parallel 5: use 5 connections, -4: use ipv4 only)
# grep the SUM and then retrieve the Mbit/sec value for the sender throughput (first line in remaining output)
uplink=$(iperf3 --client $IPERF3_HOST -f m -i 0 -t $runtime --parallel 5 -4 | grep '\[SUM\]' | awk 'NR==1{print $6; exit}')

# Output the benchmark results as one CSV line
echo "$time,$cpu,$mem,$diskRand,$diskSeq,$fork,$uplink"
