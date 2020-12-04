# Answers Exercise 2

## 1. Give a short overall explanation in your own words of what you did in this assigment.

We created multiple VMs capable of nested virtualization on gcloud, which we put in 2 virtual networks and put firewall rules in place to allow traffic between the VMs and with external machines.
We then installed OpenStack on those machines using ansible and kolla-ansible.
With OpenStack installed, we then created virtual networks in OpenStack, deployed a VM and put firewall rules in place to allow all ingress/egress traffic.
Lastly, we configured our controller VM to be able to communicate with our newly created nested VM and ran benchmarks to test the performance of the nested VM.

## 2. After creating all gc VMs, deploying OpenStack and starting an OpenStack VM, how many virtual networks are involved to establish the connectivity?

- the 2 gcloud virtual networks
- the openstack virtual network

in total 3

## 3. Initially, the OpenStack VM was not reachable from the gc controller VM (step 11). Why?

Because the gcloud controller VM did not know how to route packages to the ip addresses in the virtual network of the openstack VM.

## 4. Look into the iptables-magic.sh script. What is happening there? Describe every command with 1-2 sentences.

```
floating_subnet="10.122.0.0/24"
floating_gateway="10.122.0.1"

# add an ip address in the address range of the floating subnet to a bridge device that should connect
# the virtual networks
docker exec openvswitch_vswitchd ip a add $floating_gateway dev br-ex
# enable the bridge nic
docker exec openvswitch_vswitchd ip link set br-ex up
# set the bridge nic maximum transmission unit (MTU) to high enough for SSH traffic
docker exec openvswitch_vswitchd ip link set dev br-ex mtu 1400  # Ensure correct ssh connection

# add a route to the gcloud machine that routes all traffic of the floating ip range to the newly created bridge
ip r a "$floating_subnet" via $floating_gateway dev br-ex

# masquerade all IP packages going out of the network adapter ens4 with the internal ip of the controller VM
iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE

# Add a route to the firewall to forward all traffic coming from the ens4 nic (cc-network1) to the bridge
iptables -A FORWARD -i ens4 -o br-ex -j ACCEPT
# and add a route to forward all traffic from the bridge nic (openstack vm network) to the (cc--network1)
iptables -A FORWARD -i br-ex -o ens4 -j ACCEPT
```

## Plot descriptions

### cpu-plot

### diskRand-plot

### diskSeq-plot

### mem-plot
