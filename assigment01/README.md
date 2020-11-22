# Assigment 1

## Links

[GCP docs](https://cloud.google.com/sdk/docs/quickstart#deb)
[AWS CLI quickstart](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)

## Setup

Tested on WSL Ubuntu 20.04 on 10.11.2020

### AWS

[IAM policies](https://console.aws.amazon.com/iam/home#/home)

```sh
aws configure

```

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

```sh# Generate local key pair in file id_rsa and id_rsa.pub with
# ccuser as comment and a passphrase
ssh-keygen -t rsa -f id_rsa -C "ccuser" -N 'replaced'

# make sure to create the default vpc in case it does not exist
aws ec2 create-default-vpc

# import public key
aws ec2 import-key-pair --key-name "cckey"\
                        --public-key-material="fileb://id_rsa.pub"

# create security group for default vpc
aws ec2 create-security-group --group-name="cc-group"\
                              --description="CC VM group"

# create ssh rule for newly created security group allowing port tcp/22
aws ec2 authorize-security-group-ingress --group-name="cc-group"\
                                         --protocol="tcp"\
                                         --port=22\
                                         --cidr="0.0.0.0/0"

# create icmp rule for security group allowing all icmp ports
aws ec2 authorize-security-group-ingress --group-name="cc-group"\
                                         --protocol="icmp"\
                                         --port=-1\
                                         --cidr="0.0.0.0/0"

# create a new ec2 instance with an Ubuntu 18.04 image, t2.large type, the
# security group and add our key
aws ec2 run-instances --image-id="ami-01d4d9d5d6b52b25e"\
                      --instance-type="t2.large"\
                      --security-groups="cc-group"\
                      --key-name="cckey"

# retrieve volume_id to resize volume
# (care: when multiple instances are running, this might resize the wrong volume)
volume_id=$(aws ec2 describe-instances | grep -Po "vol-[^\"]+")

# resize the volume to 100GB
aws ec2 modify-volume --volume-id="$volume_id"\
                      --size="100"

# alternatively, create volume incase it doesnt work
aws ec2 create-volume --availability-zone="eu-central-1a" --size=100
```

#### Benchmark setup

```sh
$ public_ip=$(aws ec2 describe-instances | grep "PublicIpAddress" | grep -Po "(?:[0-9]{1,3}\.){3}[0-9]{1,3}") # retrieve public ip
$ chmod 400 id_rsa
$ ssh -i id_rsa ubuntu@public_ip
# COPY run_bench.sh to ~/run_bench.sh
$ chmod +x run_bench.sh
$ sudo apt update && sudo apt install -y sysbench
$ (crontab -l 2>/dev/null; echo "*/30 * * * * ~/run_bench.sh >> ~/aws_results.csv" ) | crontab -
```

#### Teardown

```sh
$ instance_id=$(aws ec2 describe-instances | grep "InstanceId" | grep -Po "i-[^\"]+")
$ aws ec2 terminate-instances --instance-id="$instance_id"
```

### GCP

**`spinup-gcp.sh`**

```sh
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
        --zone="europe-west1-b"
        --size=100
```

### SSHing

```sh
$ gcloud compute instances list
NAME      ZONE            MACHINE_TYPE   PREEMPTIBLE  INTERNAL_IP  EXTERNAL_IP    STATUS
cc-gcp-1  europe-west1-b  e2-standard-2               10.132.0.3   35.233.48.201  RUNNING
$ ssh ccuser@35.233.48.201 -i id_rsa
# COPY run_bench.sh to ~/run_bench.sh
$ chmod +x run_bench.sh
$ sudo apt update && sudo apt install -y sysbench
$ (crontab -l 2>/dev/null; echo "*/30 * * * * ~/run_bench.sh >> ~/benchmark.log" ) | crontab -

```

**Teardown**:

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
cpu=$(sysbench cpu --time=$time run | grep -oP 'events per second:\s*\K[0-9]+\.[0-9]+')
# run memory benchmark with block size of 4KB and total size of 100TB and match the MiB transferred using a regex
memory=$(sysbench memory --memory-block-size=4K --memory-total-size=100TB --time=$time run | grep -oP "MiB transferred \(\K[0-9]+\.[0-9]+")
# run random access disk read and sequential disk read benchmarks with 1 file of size 1GB
# and direct disk access and match the read MiB/s using a regex
rndrd=$(sysbench fileio --file-num=1 --file-test-mode=rndrd --file-total-size=1GB --file-extra-flags=direct --time=$time run | grep -oP "read, MiB\/s:\s*\K[0-9]+\.[0-9]+")
seqrd=$(sysbench fileio --file-num=1 --file-test-mode=seqrd --file-total-size=1GB --file-extra-flags=direct --time=$time run | grep -oP "read, MiB\/s:\s*\K[0-9]+\.[0-9]+")

# format all benchmarked quantities as csv
echo $timestamp,$cpu,$memory,$rndrd,$seqrd
```

### Crontab Entry

`(crontab -l 2>/dev/null; echo "*/30 * * * * ~/run_bench.sh >> ~/benchmark.log" ) | crontab -`

## Exercise 3

### CPU benchmark questions:

1. Shortly describe, how sysbench performs CPU benchmark. What does the resulting events/s value represent?

   Sysbench tests the CPU performance by verifying "prime numbers by doing standard division of the number by all numbers between 2 and the square root of the number". When started without a specified threads parameter, sysbench only uses a single thread. The resulting event/s therefore means how many prime numbers can be verified in a second using the specified numbers of threads and thus is a performance measure for the CPU speed.

2. Look at the plots of your long-term measurements. Do you see any seasonal changes?

   CPU performance degrades during working hours and increases during the night. This is probably due to the fact that the VMs share physical resources, which result in lower performance under high load, which probably happens during the day time/working hours.

### Memory benchmark questions:

1. Shortly describe, how sysbench measures memory performance.

   To test memory performance, sysbench allocates a memory buffer and then writes and reads from it using the specified amount of threads (here 1), each time for the size of a pointer (so 32bit or 64bit) until the buffer (--memory-block-size) is full. This is then repeated until the provided volume (--memory-total-size) or the execution time is reached. The resulting throughput in MiB/s then is a measure for the memory performance.

2. How would you expect virtualization to affect the memory benchmark? Why?

   A hypervisor adds additional latency to requests to physical resources, like the CPU or memory. Addtionally to the added latency, other guests might also delay the availability to the CPU or memory, thus degrading the memory benchmark performance.

### Disk benchmark questions:

1. Shortly describe, how sysbench performs the disk benchmarks.

   For the fileio benchmarks, sysbench creates a set of test files with the given total sizes (here 1 file with 1GB) and then reads sequentially or randomly from the created file until the execution time is reached. The MiB/s is then a performance measure for the disk performance.

2. Compare the results for the two operations (sequential, random). What are reasons for the differences?

   We can observe, that the sequential read performance is faster than the random read performance. This is most probably due to the fact the disks from both VMs use HDDs, which have to rotate more when reading random blocks while when reading sequentially, this delay is reduced.

### General question:

1. Compare the overall long-term measurement plots for the two platforms AWS and GCP. Name one type of application that you would expect to perform better on AWS, and one that would perform better on GCP, respectively. Shortly explain your decisions.

(The sudden drop in performance in AWS disk performance is most probably due to some "write quota" we hit since we used the cleanup command on each run, resulting in writing the test file for each benchmark. We couldn't figure out how high this quota is and had no time to rerun the full benchmark without the cleanup command.)

The VM on GCP outperforms AWS in CPU, sequential disk read and memory performance but shows a very high fluctutation in performance. AWS meanwhile outperforms GCP on random read disk speed. 

Computationally intensive applications or in-memory databases would benefit from the high memory speed and CPU speed on GCP, but might be subject to performance fluctuations thus should not be mission critical. Applications with a lot of mixed random and sequential disk access would benefit from running on AWS, since those speeds do not differ as much as on GCP. A simple database service (e.g. a users service for a social network), where you cannot make any assumptions about the pattern the data is accessed, would benefit from the random disk speed without needing high CPU performance.
