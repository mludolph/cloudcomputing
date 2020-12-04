#!/bin/bash
# create security group "open-all"

openstack security group create open-all
# add wide open rules for all tcp, udp and icmp traffic to the newly created security group
# 1 command for each protocol
openstack security group rule create --proto tcp --remote-ip 0.0.0.0/0 --dst-port 1:65525 open-all
openstack security group rule create --proto udp --remote-ip 0.0.0.0/0 --dst-port 1:65525 open-all
openstack security group rule create --proto icmp --remote-ip 0.0.0.0/0 open-all

# create keypair for openstack
openstack keypair create openstack_id_rsa > openstack_id_rsa
# retrieve external ip for gcloud controller instance
CONTROLLER_EXTERNAL_IP=$(gcloud compute instances describe controller --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone="europe-west1-b")

# copy generated private key to gcloud controller instance and set permissions to 400
scp -i id_rsa openstack_id_rsa ccuser@$CONTROLLER_EXTERNAL_IP:/home/ccuser/openstack_id_rsa
ssh ccuser@$CONTROLLER_EXTERNAL_IP -i id_rsa chmod 400 openstack_id_rsa

# create VM instance with ubuntu image, medium flavor, admin-net, default security group and the imported public key
nova boot --image="ubuntu-16.04"\
          --flavor="m1.medium"\
          --nic net-name="admin-net"\
          --security-groups="open-all"\
          --key-name="openstack_id_rsa"\
          instance1

# allocate floating ip and retrieve it from the output
floating_ip=$(openstack floating ip create --project admin\
                             --subnet external-sub external\
                             --format="value"\
                             --column="floating_ip_address")


# associate the floating ip to the instance we created earlier
openstack server add floating ip instance1 $floating_ip