#!/usr/bin/env bash

# 1. VPC networks create
gcloud compute networks create cc-network1 --subnet-mode=custom
gcloud compute networks create cc-network2 --subnet-mode=custom

# 2. VPC networks create subnets
#? wtf, what networks should I give them
gcloud compute networks subnets create cc-subnet1 \
        --network=cc-network1 \
        --range=/25 \
        --secondary-range=RANGE=

gcloud compute networks subnets create cc-subnet2 \
        --network=cc-network2 \
        --range=/25 


# 4. Create disk based on Ubuntu Server
gcloud compute disks create disk1 \
        --image-project=ubuntu-os-cloud \
        --image-family=ubuntu-1804-lts \
        --zone=europe-west1-d \
        --size=100GB

# 5. Custom image
gcloud compute images create nested-vm-image \
        --source-disk=disk1 \
        --source-disk-zone=europe-west1-d \
        --licenses="https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"

# 6. create VMs
gcloud compute instances create controller \
        --zone="europe-west1-d" \
        --min-cpu-platform="Intel Haswell" \
        --image=nested-vm-image \
        --tags=cc \
        --machine-type=n2-standard-2 \
        --network-interface=\
                --network 

# 7.firewall rule
gcloud compute firewall-rules create "cc-ssh-icmp-ingress" \
        --allow=tcp:22,icmp \
        --direction=INGRESS \
        --target-tags="cc" \
        --destination-ranges

# 8. open all openstack ports