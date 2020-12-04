# Answers Exercise 2

## 1. Give a short overall explanation in your own words of what you did in this assigment. 

## 2. After creating all gc VMs, deploying OpenStack and starting an OpenStack VM, how many virtual networks are involved to establish the connectivity?

## 3. Initially, the OpenStack VM was not reachable from the gc controller VM (step 11). Why?

## 4. Look into the iptables-magic.sh script. What is happening there? Describe every command with 1-2 sentences.

```
floating_subnet="10.122.0.0/24"
floating_gateway="10.122.0.1"

docker exec openvswitch_vswitchd ip a add $floating_gateway dev br-ex
docker exec openvswitch_vswitchd ip link set br-ex up
docker exec openvswitch_vswitchd ip link set dev br-ex mtu 1400  # Ensure correct ssh connection

ip r a "$floating_subnet" via $floating_gateway dev br-ex

iptables -t nat -A POSTROUTING -o ens4 -j MASQUERADE

iptables -A FORWARD -i ens4 -o br-ex -j ACCEPT
iptables -A FORWARD -i br-ex -o ens4 -j ACCEPT
```