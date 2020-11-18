#!/bin/bash

#ensures there is a default VPC network 
aws ec2 create-default-vpc
#imports-key-pair
aws ec2 import-key-pair --key-name "my-key" --public-key-material fileb://~/id_rsa2.pub
#creates a security group
aws ec2 create-security-group --group-name "authIncICMP" --description "allow incoming ICMP" --vpc-id "vpc-c09347bd"
#adds the allowance for incoming SSH traffic
aws ec2 authorize-security-group-ingress --group-name "authIncICMP" --protocol "tcp" --port 22 --source-group "authIncICMP"
#adds the allowance for incoming ICMP traffic
aws ec2 authorize-security-group-ingress --group-name authIncICMP --protocol "icmp" --port -1 --source-group "authIncICMP"
#start instance
aws ec2 run-instances --instance-type t2.large --key-name "my-key" --image-id="ami-08b277333b9511393" --security-groups "authIncICMP"
#resize volume
#volumeId = aws ec2 describe-volumes grep -wirn "InstanceId" | cut -d":" -f3 |cut -d" " -f2 | cut -d"," -f1
#aws ec2 modify-volume --size 100 --volume-id $volumeId
