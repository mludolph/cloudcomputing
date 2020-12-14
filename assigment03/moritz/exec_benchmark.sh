#!/bin/bash

# create result files with header
platforms="native docker kvm qemu"
for platform in $platforms; do
    echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" > "$platform-results.csv"
done

# run iperf3 server in background
iperf3 --server &

# run 10 repititons of the benchmark on the experiment host
for i in {1..10}; do
    ./benchmark.sh >> "native-results.csv"
done

# run 10 repititions of the benchmark on docker
for i in {1..10}; do
    docker run --rm docker-bench >> "docker-results.csv"
done

# retrieve guest ip of instance1 (kvm machine)
GUEST_IP=$(virsh --connect qemu:///system domifaddr instance1 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')

# vm instances are created with build-essential, sysbench, bc and iperf3 installed using cloud-init
# copy files (authentication using default private/public key)
scp {benchmark.sh,forkbench.c} ubuntu@$GUEST_IP:~
# build forkbench and chmod benchmarking script
ssh ubuntu@$GUEST_IP make forkbench && chmod +x benchmark.sh

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
