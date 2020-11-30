#!/bin/sh
# create cc-network1 and cc-network2 with custom subnet mode
gcloud compute networks create "cc-network1"\
                               --subnet-mode="custom"
gcloud compute networks create "cc-network2"\
                               --subnet-mode="custom"

# create cc-subnet1 for cc-network1 with subnet range 10.1.0.0/16 and secondary range 10.3.0.0/16
gcloud compute networks subnets create "cc-subnet1"\
                                       --network="cc-network1"\
                                       --range="10.1.0.0/16"\
                                       --secondary-range="secondary"="10.3.0.0/16"\
                                       --region="europe-west1"

# create cc-subnet2 for cc-network2 with subnet range 10.2.0.0/16
gcloud compute networks subnets create "cc-subnet2"\
                                       --network="cc-network2"\
                                       --range="10.2.0.0/16"\
                                       --region="europe-west1"

# create disk with 100GB volume and ubuntu-1604-lts image
gcloud compute disks create "image-disk"\
                            --zone="europe-west1-b"\
                            --image-project="ubuntu-os-cloud"\
                            --image-family="ubuntu-1804-lts"\
                            --size="100GB"

# create new image from the previously created disk and add the license needed for nested vms
gcloud compute images create "nested-vm-image" \
                             --source-disk="image-disk"\
                             --source-disk-zone="europe-west1-b"\
                             --licenses="https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"

# create controler vm instance as type n2-standard-2 using the nested-vm-image, cc tag, the two subnets and the secondary range in subnet1
gcloud compute instances create "controller"\
                                --zone="europe-west1-b"\
                                --machine-type="n2-standard-2"\
                                --image="nested-vm-image"\
                                --tags="cc"\
                                --network-interface subnet="cc-subnet1",aliases="secondary":"10.3.0.0/16"\
                                --network-interface subnet="cc-subnet2"

# create compute1, compute2 vm instances as type n2-standard-2 using the nested-vm-image, cc tag and the two subnets
gcloud compute instances create "compute1"\
                                --zone="europe-west1-b"\
                                --machine-type="n2-standard-2"\
                                --image="nested-vm-image"\
                                --tags="cc"\
                                --network-interface subnet="cc-subnet1"\
                                --network-interface subnet="cc-subnet2"
gcloud compute instances create "compute2"\
                                --zone="europe-west1-b"\
                                --machine-type="n2-standard-2"\
                                --image="nested-vm-image"\
                                --tags="cc"\
                                --network-interface subnet="cc-subnet1"\
                                --network-interface subnet="cc-subnet2"

# allow all internal traffic in vpcs (only to cc tagged machines)
gcloud compute firewall-rules create "cc-network1-fw1" \
        --network="cc-network1"\
        --allow=tcp,udp,icmp\
        --target-tags="cc"\
        --source-ranges="10.1.0.0/16"
gcloud compute firewall-rules create "cc-network2-fw1" \
        --network="cc-network2"\
        --allow=tcp,udp,icmp\
        --target-tags="cc"\
        --source-ranges="10.2.0.0/16"

# allow ssh and icmp from all address ranges (only to cc tagged machines)
gcloud compute firewall-rules create "cc-network1-fw2"\
                              --network="cc-network1"\
                              --target-tags="cc"\
                              --allow=tcp:22,tcp:3389,icmp
gcloud compute firewall-rules create "cc-network2-fw2"\
                              --network="cc-network2"\
                              --target-tags="cc"\
                              --allow=tcp:22,tcp:3389,icmp

# allow all traffic for network1 (only to cc tagged machines)
gcloud compute firewall-rules create "cc-network1-fw3"\
                                     --network="cc-network1"\
                                     --target-tags="cc"\
                                     --allow=tcp,icmp