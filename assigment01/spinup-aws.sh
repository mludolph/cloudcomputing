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
# volume_id=$(aws ec2 describe-instances | grep -Po "vol-[^\"]+")

# resize the volume to 100GB
# aws ec2 modify-volume --volume-id="$volume_id" --size="100"

# alternatively, create volume incase it doesnt work
aws ec2 create-volume --availability-zone="eu-central-1a" --size=100

# crontab entry with redirection to output file
# (crontab -l 2>/dev/null; echo "*/30 * * * * ~/run_bench.sh >> ~/aws_results.csv" ) | crontab -