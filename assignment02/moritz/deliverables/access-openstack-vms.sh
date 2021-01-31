#!/bin/bash
# retrieve controller external ip
CONTROLLER_EXTERNAL_IP=$(gcloud compute instances describe controller --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone="europe-west1-b")

# floating ip of the nested vm
FLOATING_IP=10.122.0.64

# create a target instance to add additional static ips to router
gcloud compute target-instances create ti-controller --instance="controller" --zone="europe-west1-b"

# create an external ip from which the nested vm will be reachable
gcloud compute addresses create ip-nvm1 --region=europe-west1
# retrieve ip to variable
NVM1_IP=$(gcloud compute addresses describe ip-nvm1 --region="europe-west1" --format='get(address)')

# forward static ip to controller
gcloud compute forwarding-rules create fw-ext-nvm1\
                                --address $NVM1_IP\
                                --target-instance="ti-controller"\
                                --target-instance-zone="europe-west1-b"\
                                --region="europe-west1"

ssh ccuser@$CONTROLLER_EXTERNAL_IP -i id_rsa sudo iptables -t nat -A PREROUTING -d $NVM1_IP -j DNAT --to-destination $FLOATING_IP

# nested vm is now reachable e.g. using ping $nvm_ip