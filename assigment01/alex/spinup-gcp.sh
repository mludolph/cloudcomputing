#!/usr/bin/env bash

# generate public key
ssh-keygen -t rsa -f ~/.ssh/gcp_key -q -P ""

# copy public key somewhere else to edit
cd ~/cloud_proj
cp ~/.ssh/gcp_key.pub gcp_key.pub 
username_key=$(cat gcp_key.pub | grep -Po '=\s(.*)' | cut -c 3-)

# at least for GCP, modify public key with username in the beginning
echo -e "$username_key: $(cat gcp_key.pub)" > gcp_key.pub 

# add public key to my project
gcloud compute project-info add-metadata --metadata-from-file ssh-keys=gcp_key.pub

# create the firewall rule
gcloud compute firewall-rules create icmpssh --target-tags=cloud-computing --allow icmp,tcp:22
#gcloud compute firewall-rules update icmpssh --target-tags=cloud-computing


# create a VM with
# machine type e2-standard-2
# tag cloud-computing
# img ubuntu server 18.04

gcloud compute instances create cloud-computing-instance --machine-type=e2-standard-2 --tags=cloud-computing --image=ubuntu-1804-bionic-v20201111  --image-project=ubuntu-os-cloud
gcloud compute disks resize cloud-computing-instance --zone=europe-west4-a --size=100GB --quiet


# gcloud beta compute project-info remove-metadata --keys=ssh-keys