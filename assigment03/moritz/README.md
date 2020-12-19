# Assigment 3 solutions

## Host setup

### Requirements

Install QEMU/KVM and enable virtualization

```sh
sudo apt-get install build-essential sysbench bc iperf3
```

### Specs

- **OS**: Ubuntu 18.04
- **CPU**: Intel Core i5 8600K 3.6GHz (6 cores)
- **RAM**: 32GB DDR4 3200MHz
- **Disk**: 256GB SATA SSD

### Software versions

```sh

$ kvm --version
> QEMU emulator version 2.12.0 (Debian 1:2.12+dfsg-0~18.04~ppa0)

$ virsh --version
4.7.0

$ iperf3 --version
iperf 3.7 (cJSON 1.5.2)

$ sysbench --version
sysbench 1.0.11

$ bc --version
bc 1.07.1
```

## Creating VMs

```sh
# Download ubuntu cloud image
wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

# Create folder
sudo mkdir /var/lib/libvirt/images/base

# Move image
sudo mv bionic-server-cloudimg-amd64.img /var/lib/libvirt/images/base/ubuntu-18.04.qcow2

# Create folder for instance
sudo mkdir /var/lib/libvirt/images/instance1
sudo mkdir /var/lib/libvirt/images/instance2

# Create image
sudo qemu-img create -f qcow2 -o backing_file=/var/lib/libvirt/images/base/ubuntu-18.04.qcow2 /var/lib/libvirt/images/instance1/instance1.qcow2

sudo qemu-img create -f qcow2 -o backing_file=/var/lib/libvirt/images/base/ubuntu-18.04.qcow2 /var/lib/libvirt/images/instance2/instance2.qcow2

# Resize image
sudo qemu-img resize /var/lib/libvirt/images/instance1/instance1.qcow2 15G
sudo qemu-img resize /var/lib/libvirt/images/instance2/instance2.qcow2 15G


export PUB_KEY=$(cat ~/.ssh/id_rsa.pub)
# Create meta-data and user-data for cloudinit
mkdir instance1 && mkdir instance2

cd instance1

cat >meta-data <<EOF
local-hostname: instance1
EOF

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
packages:
  - build-essential
  - iperf3
  - bc
  - sysbench
EOF

sudo genisoimage  -output /var/lib/libvirt/images/instance1/instance1-cidata.iso -volid cidata -joliet -rock user-data meta-data

cd ../instance2

cat >meta-data <<EOF
local-hostname: instance2
EOF

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
packages:
  - build-essential
  - iperf3
  - bc
  - sysbench
EOF

# Create cloudinit iso image
sudo genisoimage  -output /var/lib/libvirt/images/instance2/instance2-cidata.iso -volid cidata -joliet -rock user-data meta-data

VCPUS=$(nproc)
MEMORY=4096

# Create instance
virt-install --connect qemu:///system --virt-type kvm --name instance1 --ram $MEMORY --vcpus=$VCPUS --os-type linux --os-variant ubuntu18.04 --disk path=/var/lib/libvirt/images/instance1/instance1.qcow2,format=qcow2,cache=none --disk /var/lib/libvirt/images/instance1/instance1-cidata.iso,device=cdrom --import --network network=default --noautoconsole

virt-install --connect qemu:///system --virt-type qemu --name instance2 --ram $MEMORY --vcpus=$VCPUS --os-type linux --os-variant ubuntu18.04 --disk path=/var/lib/libvirt/images/instance2/instance2.qcow2,format=qcow2,cache=none --disk /var/lib/libvirt/images/instance2/instance2-cidata.iso,device=cdrom --import --network network=default --noautoconsole

virsh --connect qemu:///system list
virsh --connect qemu:///system domifaddr instance1
virsh --connect qemu:///system domifaddr instance2

# shutdown
virsh --connect qemu:///system shutdown instance1
virsh --connect qemu:///system shutdown instance2

# teardown
virsh --connect qemu:///system undefine instance1
virsh --connect qemu:///system undefine instance2
```


# Question answers
## CPU
Qemu without hardware support emulates the CPU in software which results in a great loss in performance compared to the others. When the KVM is used as an accelerator for QEMU the physical CPU virtualization extensions can be used. This leads to identical performance compared to native System. The Docker containers performance is also similar to the native system due to the unlimited access to the hosts CPU. 

## diskRand
In KVM the default cache mode is writeback. In this mode O_DSYNC, which makes every write() to the file return only when the contents of the file have been written to disk, is disabled. This means the host page cache is used and writes are reported to the guest as completed when placed in the host page cache. This results in a better performance but depending on the hardware it can lead to a data loss in a power outage.

## diskSeq
This result underpins what has been seen in the previous plots of this assignment. The KVM has the best performance which can be attributed to the writeback caching. The performance of Docker and QEMU was worse compared to the nativ system due to the additional latency of the docker daemon.
