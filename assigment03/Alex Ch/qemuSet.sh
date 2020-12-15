#!/bin/bash

#create ssh key in VM
ssh-keygen -t rsa -f ~/.ssh/id_rsa -C ik78evah -N''
#upgrade packages
sudo apt-get update
#install qemu-kvm, libvirt-bin, qemu-utils, genisoimage, virtinst
sudo apt install qemu-kvm libvirt-bin qemu-utils genisoimage virtinst
#start libvirt daemon
sudo service libvirtd start
#Download Ubuntu cloud image
wget https://cloud-images.ubuntu.com/xenial/current/xenial-server-cloudimg-amd64-disk1.img
#Create directory for base images:
sudo mkdir /var/lib/libvirt/images/base
#move downloaded image with new name into folder:
sudo mv xenial-server-cloudimg-amd64-disk1.img /var/lib/libvirt/images/base/ubuntu-16.04.qcow2
#Create directory for the instance images:
sudo mkdir /var/lib/libvirt/images/instance-1
#Create a disk image based on the Ubuntu image:
sudo qemu-img create -f qcow2 -o backing_file=/var/lib/libvirt/images/base/ubuntu-16.04.qcow2 /var/lib/libvirt/images/instance-1/instance-1.qcow2
#Create meta-data:
cat >meta-data <<EOF
local-hostname: instance-1
EOF
#read public key into environment variable:
export PUB_KEY=$(cat ~/.ssh/id_rsa.pub)
#Create user-data:
cat >user-data <<EOF
#cloud-config
users:
  - name: ubuntu
    ssh-authorized-keys:
      - $PUB_KEY
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    groups: sudo
    shell: /bin/bash
runcmd:
  - echo "AllowUsers ubuntu" >> /etc/ssh/sshd_config
  - restart ssh
EOF
#Create a disk to attach with Cloud-Init configuration:
sudo genisoimage  -output /var/lib/libvirt/images/instance-1/instance-1-cidata.iso -volid cidata -joliet -rock user-data meta-data
#launch virtual machine
sudo virt-install --connect qemu:///system --virt-type kvm --name instance-1 --ram 1024 --vcpus=1 --os-type linux --os-variant ubuntu16.04 --disk path=/var/lib/libvirt/images/instance-1/instance-1.qcow2,format=qcow2 --disk /var/lib/libvirt/images/instance-1/instance-1-cidata.iso,device=cdrom --import --network network=default --noautoconsole
#post virtual machine info
sudo virsh list
#post instructions for ssh connection to qemu instance-1
echo "run: sudo virsh domifaddr instance-1 top get the IP of instance-1"
echo "to connect to instance-1 run: ssh ubuntu@IpAddressOfInstance-1 (without /..)"
