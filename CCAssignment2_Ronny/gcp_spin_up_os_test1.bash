
# set project
gcloud config set project test03script

# create first vpc network 
gcloud compute networks create cc-network1 --project=test03script --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional
#create first subnet
gcloud compute networks subnets create cc-subnet1 --project=test03script --range=10.0.0.0/9 --network=cc-network1 --region=us-west1  --secondary-range=10.3.0.0/16
#create second vpc network
gcloud compute networks create cc-network2 --project=test03script --subnet-mode=custom --mtu=1460 --bgp-routing-mode=regional
#create 2nd subnet additionally with secondary range parameter
gcloud compute networks subnets create cc-subnet2 --project=test03script --range=10.0.0.0/9 --network=cc-network2 --region=us-west1 

 # Family-Name: ubuntu-1804-lts
 # create disk with image based on "Ubuntu Server 18.04" in default zone (europe-west1-b) and 
 gcloud compute disks create test01nvs --image-project ubuntu-os-cloud --image-family ubuntu-1804-lts --zone europe-west1-b --size 100
 
 # Create a custom image with the special license key required for virtualization
 gcloud compute images create nested-test --source-disk test01nvs --source-disk-zone europe-west1-b --licenses "https://www.googleapis.com/compute/v1/projects/vm-options/global/licenses/enable-vmx"
 
 # gcloud Compute instance 1 and name it controller
 gcloud compute instances create "controller"\
                                --zone="europe-west1-b"\
                                --machine-type="n2-standard-2"\
                                --image="nested-test"\
                                --tags="cc"\
                                --network-interface subnet="cc-subnet1",aliases="secondary":"1.0.1.0/24"\
                                --network-interface subnet="cc-subnet2"

# create compute1, compute2 vm instances as type n2-standard-2 using the nested-vm-image, cc tag and the two subnets
gcloud compute instances create "compute1"\
                                --zone="europe-west1-b"\
                                --machine-type="n2-standard-2"\
                                --image="nested-test"\
                                --tags="cc"\
                                --network-interface subnet="cc-subnet1"\
                                --network-interface subnet="cc-subnet2"
gcloud compute instances create "compute2"\
                                --zone="europe-west1-b"\
                                --machine-type="n2-standard-2"\
                                --image="nested-test"\
                                --tags="cc"\
                                --network-interface subnet="cc-subnet1"\
                                --network-interface subnet="cc-subnet2"