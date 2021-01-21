#!/bin/bash
#creates a new ssh key 
ssh-keygen -t rsa -f ~/id_rsa -N ' ' -C ik78evah
#restricts access
chmod 400 ~/id_rsa 
#formats the ssh key adding the username to the beginning of the string
echo -n "ik78evah:" > temp
cat id_rsa.pub >> temp
cat temp > id_rsa.pub
rm temp
#sets "project practical-assignment-no-1" to the active configuration
gcloud config set project practical-assignment-no-1
#uploads the ssh public key
gcloud compute config-ssh --ssh-key-file=~/id_rsa
#Create firewall rule allowing incoming ICMP
gcloud compute firewall-rules create myrule1 --allow ICMP --direction=INGRESS --source-tags cloud-computing
#Create firewall rule allowing incoming SSH by allowing incoming at the standard SSH gate: TCP:22
gcloud compute firewall-rules create myrule2 --allow TCP:22 --direction=INGRESS --source-tags cloud-computing
#Launch instance in central us with an ubuntu 18.04 image
gcloud compute instances create instance-1 --zone=us-central1-a --machine-type=e2-standard-2 --image=ubuntu-1804-bionic-v20201111 --image-project=ubuntu-os-cloud
#resize the disk to 100GB
gcloud compute disks resize instance-1 --size=100GB --zone=us-central1-a

#*/30 * * * * /home/benchScript.sh >> gcp_results.csv
