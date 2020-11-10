# Assigment 1

## Links

[GCP docs](https://cloud.google.com/sdk/docs/quickstart#deb)

## Setup

Tested on WSL Ubuntu 20.04 on 10.11.2020

### AWS

<span style="color:red">TODO</span>

### GCP

#### Installing the CLI

```sh
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
sudo apt-get install apt-transport-https ca-certificates gnupg
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update && sudo apt-get install google-cloud-sdk
```

#### Project initialization

```sh
gcloud init
gcloud project create <project_name>
gcloud config set project <project_name>
```

## Exercise 1

### AWS

**`spinup-aws.sh`**

<span style="color: red;"> TODO </span>

### GCP

**`spinup-gcp.sh`**

```sh
# Generate local key pair in file id_rsa and id_rsa.pub with
# ccuser as comment and an empty passphrase
ssh-keygen -t rsa -f id_rsa -C "ccuser" -N ''

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
        --zone="europe-west1-b"
        --size=100
```

**Teardown (don't include)**:

```sh
gcloud compute instances delete "cc-gcp-1"
```

## Exercise 2

**Preperation**:
`sudo apt update && sudo apt install -y sysbench`

**`run_bench.sh`**

```sh
# length of individual benchmarks in seconds set to 60
time=60

# prepare file benchmark with 1 file of size 1GB, discard output
sysbench fileio --file-num=1 --file-total-size=1GB prepare > /dev/null

# get the timestamp before the measurements are started
timestamp=$(date +%s)

# run cpu benchmark (no additional requirements stated) and match events per second using regex
cpu=$(sysbench cpu --time=$time run | grep -oP 'events per second:\s*\K[0-9]+.[0-9]+')
# run memory benchmark with block size of 4KB and total size of 100TB and match the MiB transferred using a regex
memory=$(sysbench memory --memory-block-size=4K --memory-total-size=100TB --time=$time run | grep -oP "MiB transferred \(\K[0-9]+.[0-9]+")
# run random access disk read and sequential disk read benchmarks with 1 file of size 1GB 
# and direct disk access and match the read MiB/s using a regex
rndrd=$(sysbench fileio --file-num=1 --file-test-mode=rndrd --file-total-size=1GB --file-extra-flags=direct --time=$time run | grep -oP "read, MiB\/s:\s*\K[0-9]+\.[0-9]+")
seqrd=$(sysbench fileio --file-num=1 --file-test-mode=seqrd --file-total-size=1GB --file-extra-flags=direct --time=$time run | grep -oP "read, MiB\/s:\s*\K[0-9]+\.[0-9]+")

# format all benchmarked quantities as csv
echo $timestamp,$cpu,$memory,$rndrd,$seqrd
```

## Exercise 3

```


```