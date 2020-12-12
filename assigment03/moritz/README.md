# Assigment 3 solutions


```sh
# Download ubuntu cloud image
wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

# Create folder
sudo mkdir /var/lib/libvirt/images/base

# Move image
sudo mv bionic-server-cloudimg-amd64.img /var/lib/libvirt/images/base/ubuntu-18.04.qcow2

# Create folder for instance
sudo mkdir /var/lib/libvirt/images/instance1

# Create image
sudo qemu-img create -f qcow2 -o backing_file=/var/lib/libvirt/images/base/ubuntu-18.04.qcow2 /var/lib/libvirt/images/instance1/instance1.qcow2

# Resize image
sudo qemu-img resize /var/lib/libvirt/images/instance1/instance1.qcow2 15G

# Create meta-data and user-data for cloudinit
cat >meta-data <<EOF
local-hostname: instance1
EOF

export PUB_KEY=$(cat ~/.ssh/id_rsa.pub)
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

# Create cloudinit iso image 

sudo genisoimage  -output /var/lib/libvirt/images/instance1/instance1-cidata.iso -volid cidata -joliet -rock user-data meta-data

VCPUS=$(nproc)
MEMORY=4096
TYPE=kvm # exchange for qemu

# Create instance
virt-install --connect qemu:///system --virt-type $TYPE --name instance1 --ram $MEMORY --vcpus=$VCPUS --os-type linux --os-variant ubuntu18.04 --disk path=/var/lib/libvirt/images/instance1/instance1.qcow2,format=qcow2 --disk /var/lib/libvirt/images/instance1/instance1-cidata.iso,device=cdrom --import --network network=default --noautoconsole

sudo virsh list
sudo virsh domifaddr instance1
ssh ubuntu@<ip>

# shutdown
sudo virsh shutdown instance1

# teardown
sudo virsh undefine instance1
```

```sh
# copy forkbench to system and use make forkbench.c or
gcc forkbench.c -o forkbench
```
