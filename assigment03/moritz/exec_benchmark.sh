#!/bin/bash

# create result files with header
platforms="native docker kvm qemu"
for platform in $platforms; do
    echo "time,cpu,mem,diskRand,diskSeq,fork,uplink" > "$platform-results.csv"
done

echo "Starting iperf3 server..."
# run iperf3 server in background
iperf3 --server &>/dev/null &
export IPERF3_HOST=$(ip route get 1 | awk '{print $7;exit}')

echo "Running native benchmarks..."
# run 10 repititons of the benchmark on the experiment host
for i in {1..10}; do
    2>/dev/null ./benchmark.sh >> "native-results.csv"
done

echo "Running docker benchmarks..."
# docker image was created using 'docker image build . -t docker-bench'
# run 10 repititions of the benchmark on docker
for i in {1..10}; do
    docker run --rm --env IPERF3_HOST=$IPERF3_HOST docker-bench >> "docker-results.csv"
done

# retrieve guest ip of instance1 (kvm machine)
INSTANCE1_IP=$(virsh --connect qemu:///system domifaddr instance1 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')

echo "Copying files to kvm vm..."
# vm instances are created with build-essential, sysbench, bc and iperf3 installed using cloud-init
# copy files (authentication using default private/public key)
scp {benchmark.sh,forkbench.c} ubuntu@$INSTANCE1_IP:~
# build forkbench and chmod benchmarking script
ssh ubuntu@$INSTANCE1_IP make forkbench && chmod +x benchmark.sh

echo "Running kvm vm benchmarks..."
# run 10 repititions of the benchmark on kvm vm
for i in {1..10}; do
    ssh ubuntu@$INSTANCE1_IP IPERF3_HOST=$IPERF3_HOST 2>/dev/null bash benchmark.sh  >> "kvm-results.csv"
done

INSTANCE2_IP=$(virsh --connect qemu:///system domifaddr instance2 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')

echo "Copying files to qemu vm..."
# vm instances are created with build-essential, sysbench, bc and iperf3 installed using cloud-init
# copy files (authentication using default private/public key)
scp {benchmark.sh,forkbench.c} ubuntu@$INSTANCE2_IP:~
# build forkbench and chmod benchmarking script
ssh ubuntu@$INSTANCE2_IP make forkbench && chmod +x benchmark.sh

echo "Running benchmarks on vm..."
# run 10 repititions of the benchmark on kvm vm
for i in {1..10}; do
    ssh ubuntu@$INSTANCE2_IP IPERF3_HOST=$IPERF3_HOST 2>/dev/null bash benchmark.sh  >> "qemu-results.csv"
done
