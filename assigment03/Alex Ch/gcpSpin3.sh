#!/bin/bash
gcloud compute disks create "image-disk" --zone="europe-west1-b" --image-project="ubuntu-os-cloud" --image-family="ubuntu-1804-lts" --size="100GB"

# create new image from the previously created disk and add the license needed for nested vms
gcloud compute images create "nested-vm-image" --source-disk="image-disk" --source-disk-zone="europe-west1-b" --licenses="https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"


# create VM that is capable of nested virtualization
gcloud compute instances create "nes-vm" --zone="europe-west1-b" --machine-type="n2-standard-2" --image="nested-vm-image"

#post further instructions
echo "upload qemuSet.sh via:   scp qemuSet user@VmExIp     and ssh into the VM"

