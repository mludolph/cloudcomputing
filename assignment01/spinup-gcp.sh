# Generate local key pair in file id_rsa and id_rsa.pub with
# ccuser as comment and an empty passphrase
ssh-keygen -t rsa -f id_rsa -C "ccuser" -N 'replaced'

# Save a GCP formatted copy to gcp_key.pub by inserting "[USERNAME]:"
# in front of the public key in id_rsa.pub
echo -e "ccuser:$(cat id_rsa.pub)" > gcp_key.pub

# Add the SSH key to the project meta data by providing the corresponding
# file
gcloud compute project-info add-metadata \
        --metadata-from-file ssh-keys=gcp_key.pub

# Create a firewall rule for ssh (tcp:22) and icmp ingress called
# "cc-ssh-icmp-ingress" affecting only targets with tag "cloud-computing"
gcloud compute firewall-rules create "cc-ssh-icmp-ingress" \
        --allow=tcp:22,icmp \
        --direction=INGRESS \
        --target-tags="cloud-computing"

# Create a compute instance called "cc-gcp-1" from the ubuntu-1804-lts image
# family, machine type "e2-standard-2" and the tag "cloud-computing"
gcloud compute instances create "cc-gcp-1" \
        --zone="europe-west1-b" \
        --image-project="ubuntu-os-cloud"\
        --image-family="ubuntu-1804-lts"\
        --machine-type="e2-standard-2"\
        --tags="cloud-computing"

# Resize the disk of compute instance "cc-gcp-1" to 100GB
gcloud compute disks resize "cc-gcp-1" \
        --zone="europe-west1-b"\
        --size=100

# crontab entry with redirection to output file
# (crontab -l 2>/dev/null; echo "*/30 * * * * ~/run_bench.sh >> ~/gcp_results.csv" ) | crontab -