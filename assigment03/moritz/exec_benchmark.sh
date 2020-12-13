#!/bin/bash

# create result files with header
platforms="native docker kvm qemu"
for platform in $platforms; do
    echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" > "$platform-results.csv"
done

# run 10 repititons of the benchmark on the experiment host
for i in {1..10}; do
    ./benchmark.sh >> "native-results.csv"
done

# run 10 repititions of the benchmark on docker
for i in {1..10}; do
    docker run --rm docker-bench >> "docker-results.csv"
done

# copy files to kvm vm with scp
echo "TODO SCP COPY"

# run 10 repititions of the benchmark on kvm vm
for i in {1..10}; do
    echo "NotImplemented"
done

# copy files to qemu vm with scp
echo "TODO SCP COPY"

# run 10 repititions of the benchmark on qemu vm
for i in {1..10}; do
    echo "NotImplemented"
done
