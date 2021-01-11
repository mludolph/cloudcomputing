# Assignment 4
**AV steps**

0. Setup 3 VMs which will be used for the Kube cluster

I used *GCP* VMs as my Linux machine runs Ubuntu 20.04 and I wanted to avoid last assignment's misery.

Easy way, as used on previous assignments (clearly stolen from Moritz's assignment 2 readme)
```bash
### INFRASTRUCTURE
gcloud compute networks create "cc-network1"\
                               --subnet-mode="custom"

gcloud compute networks subnets create "cc-subnet1"\
                                       --network="cc-network1"\
                                       --range="10.1.0.0/16"\
                                       --region="europe-west1"

gcloud compute disks create "image-disk"\
                            --zone="europe-west1-b"\
                            --image-project="ubuntu-os-cloud"\
                            --image-family="ubuntu-1804-lts"\
                            --size="100GB"

gcloud compute images create "nested-vm-image" \
                             --source-disk="image-disk"\
                             --source-disk-zone="europe-west1-b"\
                             --licenses="https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"

### ACTUAL VM CREATION
gcloud compute instances create "worker0"\
                                --zone="europe-west1-b"\
                                --machine-type="n2-standard-2"\
                                --image="nested-vm-image"\
                                --tags="cc"\
                                --network-interface subnet="cc-subnet1"       

# create compute1, compute2 vm instances as type n2-standard-2 using the nested-vm-image, cc tag and the two subnets
gcloud compute instances create "worker1"\
                                --zone="europe-west1-b"\
                                --machine-type="n2-standard-2"\
                                --image="nested-vm-image"\
                                --tags="cc"\
                                --network-interface subnet="cc-subnet1"

gcloud compute instances create "worker2"\
                                --zone="europe-west1-b"\
                                --machine-type="n2-standard-2"\
                                --image="nested-vm-image"\
                                --tags="cc"\
                                --network-interface subnet="cc-subnet1"

### NETWORKING
# allow all internal traffic in vpcs (only to cc tagged machines)
gcloud compute firewall-rules create "cc-network1-fw1" \
        --network="cc-network1"\
        --allow=tcp,udp,icmp\
        --target-tags="cc"\
        --source-ranges="10.1.0.0/16"

# allow ssh and icmp from all address ranges on first network (only to cc tagged machines)
gcloud compute firewall-rules create "cc-network1-fw2"\
                              --network="cc-network1"\
                              --target-tags="cc"\
                              --allow=tcp:22,tcp:3389,icmp

# allow all traffic for network1 (only to cc tagged machines) needed for openstack
gcloud compute firewall-rules create "cc-network1-fw3"\
                                     --network="cc-network1"\
                                     --target-tags="cc"\
                                     --allow=tcp,icmp
                                                     

```

**TO MAKE LIFE EASIER FROM NOW ON**

retrieve the machines' IP addresses if necessary.

```bash
VM1_EXTERNAL_IP=$(gcloud compute instances describe worker0 --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone="europe-west1-b")
VM1_INTERNAL_IP1=$(gcloud compute instances describe worker0 --format='get(networkInterfaces[0].networkIP)' --zone="europe-west1-b")
VM1_INTERNAL_IP2=$(gcloud compute instances describe worker0 --format='get(networkInterfaces[1].networkIP)' --zone="europe-west1-b")
VM2_EXTERNAL_IP=$(gcloud compute instances describe worker1 --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone="europe-west1-b")
VM2_INTERNAL_IP1=$(gcloud compute instances describe worker1 --format='get(networkInterfaces[0].networkIP)' --zone="europe-west1-b")
VM2_INTERNAL_IP2=$(gcloud compute instances describe worker1 --format='get(networkInterfaces[1].networkIP)' --zone="europe-west1-b")
VM3_EXTERNAL_IP=$(gcloud compute instances describe worker2 --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone="europe-west1-b")
VM3_INTERNAL_IP1=$(gcloud compute instances describe worker2 --format='get(networkInterfaces[0].networkIP)' --zone="europe-west1-b")
VM3_INTERNAL_IP2=$(gcloud compute instances describe worker2 --format='get(networkInterfaces[1].networkIP)' --zone="europe-west1-b")
```

Afterwards, connect to each and run

```bash
sudo apt update && sudo apt upgrade
sudo apt install python-pip
```

In case access to default root user "ubuntu" is needed, run this to reset password:

```bash
sudo passwd
```
[Source: stackoverflow... ](https://stackoverflow.com/questions/35992511/how-do-i-set-my-user-password-on-my-google-cloud-ubuntu-instance)

1. Set up the Kubernetes Cluster

* Clone Kubespray repo on local machine

```bash
git clone git@github.com:kubernetes-sigs/kubespray.git
cd kubespray
git checkout 'v2.14.2'
```
* create hosts.yml or hosts.ini

**package conflict found**

I needed to install ruamel and got following feedback

```bash
  - ruamel -> python[version='>=2.7,<2.8.0a0|>=3.6,<3.7.0a0|>=3.7,<3.8.0a0|>=3.8,<3.9.0a0']

```

Use env with python 3.8, not 3.9.

```bash
conda create -n "cloud_as4" python=3.8
```

[Kubespray getting started](https://github.com/kubernetes-sigs/kubespray/blob/master/docs/getting-started.md)

```bash
cp -r inventory/sample inventory/mycluster
declare -a IPS=($VM1_EXTERNAL_IP $VM2_EXTERNAL_IP $VM3_EXTERNAL_IP)
CONFIG_FILE=inventory/mycluster/hosts.yml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
```

