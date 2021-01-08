# Assigment 4

## VM setup

```sh
wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img

# Create folder
sudo mkdir /var/lib/libvirt/images/base

# Move image
sudo mv bionic-server-cloudimg-amd64.img /var/lib/libvirt/images/base/ubuntu-18.04.qcow2

# Create folder for instance
sudo mkdir /var/lib/libvirt/images/instance1
sudo mkdir /var/lib/libvirt/images/instance2
sudo mkdir /var/lib/libvirt/images/instance3

# Create image
sudo qemu-img create -f qcow2 -o backing_file=/var/lib/libvirt/images/base/ubuntu-18.04.qcow2 /var/lib/libvirt/images/instance1/instance1.qcow2
sudo qemu-img create -f qcow2 -o backing_file=/var/lib/libvirt/images/base/ubuntu-18.04.qcow2 /var/lib/libvirt/images/instance2/instance2.qcow2
sudo qemu-img create -f qcow2 -o backing_file=/var/lib/libvirt/images/base/ubuntu-18.04.qcow2 /var/lib/libvirt/images/instance3/instance3.qcow2

# Resize image
sudo qemu-img resize /var/lib/libvirt/images/instance1/instance1.qcow2 15G
sudo qemu-img resize /var/lib/libvirt/images/instance2/instance2.qcow2 15G
sudo qemu-img resize /var/lib/libvirt/images/instance3/instance3.qcow2 15G


export PUB_KEY=$(cat ~/.ssh/id_rsa.pub)
# Create meta-data and user-data for cloudinit
mkdir instance1

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
  - python-pip
  - python-setuptools
  - python-virtualenv
EOF

sudo genisoimage  -output /var/lib/libvirt/images/instance1/instance1-cidata.iso -volid cidata -joliet -rock user-data meta-data
sudo genisoimage  -output /var/lib/libvirt/images/instance2/instance2-cidata.iso -volid cidata -joliet -rock user-data meta-data
sudo genisoimage  -output /var/lib/libvirt/images/instance3/instance3-cidata.iso -volid cidata -joliet -rock user-data meta-data

VCPUS=2
MEMORY=4096

# Create instance
virt-install --connect qemu:///system --virt-type kvm --name instance1 --ram $MEMORY --vcpus=$VCPUS --os-type linux --os-variant ubuntu18.04 --disk path=/var/lib/libvirt/images/instance1/instance1.qcow2,format=qcow2,cache=none --disk /var/lib/libvirt/images/instance1/instance1-cidata.iso,device=cdrom --import --network network=default --noautoconsole

virt-install --connect qemu:///system --virt-type kvm --name instance2 --ram $MEMORY --vcpus=$VCPUS --os-type linux --os-variant ubuntu18.04 --disk path=/var/lib/libvirt/images/instance2/instance2.qcow2,format=qcow2,cache=none --disk /var/lib/libvirt/images/instance2/instance2-cidata.iso,device=cdrom --import --network network=default --noautoconsole

virt-install --connect qemu:///system --virt-type kvm --name instance3 --ram $MEMORY --vcpus=$VCPUS --os-type linux --os-variant ubuntu18.04 --disk path=/var/lib/libvirt/images/instance3/instance3.qcow2,format=qcow2,cache=none --disk /var/lib/libvirt/images/instance3/instance3-cidata.iso,device=cdrom --import --network network=default --noautoconsole



virsh --connect qemu:///system list
virsh --connect qemu:///system domifaddr instance1

node1_ip=$(virsh --connect qemu:///system domifaddr instance1 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')
node2_ip=$(virsh --connect qemu:///system domifaddr instance2 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')
node3_ip=$(virsh --connect qemu:///system domifaddr instance3 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')


# make sure ssh access is password-less
eval `ssh-agent`
ssh-add

ssh ubuntu@$node1_ip
ssh ubuntu@$node2_ip
ssh ubuntu@$node3_ip

```

## Exercise 1

```sh
git clone --depth 1 --branch v2.14.2 https://github.com/kubernetes-sigs/kubespray

python3 -m venv .venv
source .venv/bin/activate

pip install -r kubespray/requirements.txt

cd kubespray

declare -a IPS=($node1_ip $node2_ip $node3_ip)
CONFIG_FILE=inventory/mycluster/hosts.yaml python3 contrib/inventory_builder/inventory.py ${IPS[@]}
# 192.168.122.80 192.168.122.113 192.168.122.168
```

### Setup k8s

```sh
ansible-playbook -i inventory/mycluster/hosts.yaml cluster.yml
```

#### Get cluster info

```sh
ssh ubuntu@$node1_ip

kubectl cluster-info > info.txt
kubectl get node >> info.txt
```

#### Fix in case kubectl is not working

```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### Get cluster info to file

`commands.txt`

```sh
# build docker images from respective Dockerfiles, context of local directory and tag them
docker build -f frontend.Dockerfile -t mludolph/images:ccfrontend .
docker build -f backend.Dockerfile -t mludolph/images:ccbackend .

# login to dockerhub to push images to repository
docker login

# push the images to the public dockerhub repository
docker push mludolph/images:ccfrontend
docker push mludolph/images:ccbackend

# run ansible-playbook from local machine
ansible-playbook -i hosts.yml webapp.yml

# get node port by running the following 2 lines from the node1, i.e. ssh into node1 e.g. using ssh ubuntu@$node1_ip
node_port=$(kubectl get svc cc-frontend-service -n cc -o=jsonpath='{.spec.ports[?(@.port==80)].nodePort}')
echo $node_port


# create variables with the nodeport from the stop above and the ips of the 3 nodes
node_port=30339
node1_ip=192.168.122.80
node2_ip=192.168.122.113
node3_ip=192.168.122.168

# run the python script and redirect the output to the test-outpu.txt
python3 test-deployment.py $node1_ip:$node_port $node2_ip:$node_port $node3_ip:$node_port > test-output.txt
#
```
