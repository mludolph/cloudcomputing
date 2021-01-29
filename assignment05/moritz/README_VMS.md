

## Exercise 2: VM clusters

```bash
# Get IP addresses of all nodes (QEMU VMs in this case)
node1_ip=$(virsh --connect qemu:///system domifaddr instance1 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')
node2_ip=$(virsh --connect qemu:///system domifaddr instance2 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')
node3_ip=$(virsh --connect qemu:///system domifaddr instance3 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')

# install java on all nodes
ssh ubuntu@$node1_ip "sudo apt-get update & sudo apt-get -y install openjdk-8-jdk"
ssh ubuntu@$node2_ip "sudo apt-get update & sudo apt-get -y install openjdk-8-jdk"
ssh ubuntu@$node3_ip "sudo apt-get update & sudo apt-get -y install openjdk-8-jdk"

# OPTIONAL: test java installation
ssh ubuntu@$node1_ip "java -version"
ssh ubuntu@$node2_ip "java -version"
ssh ubuntu@$node3_ip "java -version"

# download, unpack and move hadoop on all nodes
ssh ubuntu@$node1_ip "wget -q https://mirror.synyx.de/apache/hadoop/common/hadoop-3.3.0/hadoop-3.3.0.tar.gz && tar xzf hadoop-3.3.0.tar.gz && mv hadoop-3.3.0 hadoop"
ssh ubuntu@$node2_ip "wget -q https://mirror.synyx.de/apache/hadoop/common/hadoop-3.3.0/hadoop-3.3.0.tar.gz && tar xzf hadoop-3.3.0.tar.gz && mv hadoop-3.3.0 hadoop"
ssh ubuntu@$node3_ip "wget -q https://mirror.synyx.de/apache/hadoop/common/hadoop-3.3.0/hadoop-3.3.0.tar.gz && tar xzf hadoop-3.3.0.tar.gz && mv hadoop-3.3.0 hadoop"

# set hadoop java environment
ssh ubuntu@$node1_ip "echo \"export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64\" >> ~/hadoop/etc/hadoop/hadoop-env.sh"
ssh ubuntu@$node2_ip "echo \"export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64\" >> ~/hadoop/etc/hadoop/hadoop-env.sh"
ssh ubuntu@$node3_ip "echo \"export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64\" >> ~/hadoop/etc/hadoop/hadoop-env.sh"

# move hadoop to /usr/local/hadoop
ssh ubuntu@$node1_ip "sudo mv hadoop /usr/local/hadoop"
ssh ubuntu@$node2_ip "sudo mv hadoop /usr/local/hadoop"
ssh ubuntu@$node3_ip "sudo mv hadoop /usr/local/hadoop"


# add hadoop dns to all nodes
ssh ubuntu@$node1_ip "echo \"${node1_ip}    hadoop-master\" | sudo tee -a /etc/hosts && 
                      echo \"${node2_ip}    hadoop-slave1\" | sudo tee -a /etc/hosts &&
                      echo \"${node3_ip}    hadoop-slave2\" | sudo tee -a /etc/hosts"

ssh ubuntu@$node2_ip "echo \"${node1_ip}    hadoop-master\" | sudo tee -a /etc/hosts && 
                      echo \"${node2_ip}    hadoop-slave1\" | sudo tee -a /etc/hosts &&
                      echo \"${node3_ip}    hadoop-slave2\" | sudo tee -a /etc/hosts"

ssh ubuntu@$node3_ip "echo \"${node1_ip}    hadoop-master\" | sudo tee -a /etc/hosts && 
                      echo \"${node2_ip}    hadoop-slave1\" | sudo tee -a /etc/hosts &&
                      echo \"${node3_ip}    hadoop-slave2\" | sudo tee -a /etc/hosts"

# generate key on master and copy to all nodes
ssh ubuntu@$node1_ip "ssh-keygen -q -t rsa -N '' -f ~/.ssh/id_rsa"
ssh ubuntu@$node1_ip "ssh-copy-id ubuntu@hadoop-master"
ssh ubuntu@$node1_ip "ssh-copy-id ubuntu@hadoop-slave1"
ssh ubuntu@$node1_ip "ssh-copy-id ubuntu@hadoop-slave2"
```
