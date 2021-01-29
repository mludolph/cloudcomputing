## Exercise 2: VM clusters

```bash
# get IP addresses of all nodes (QEMU VMs in this case)
node1_ip=$(virsh --connect qemu:///system domifaddr instance1 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')
node2_ip=$(virsh --connect qemu:///system domifaddr instance2 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')
node3_ip=$(virsh --connect qemu:///system domifaddr instance3 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')

# generate an SSH key and exchange key between nodes so that nodes can SSH to eachother
ssh-keygen -q -t rsa -N '' -f ./id_rsa
ssh-copy-id -i id_rsa ubuntu@$node1_ip
ssh-copy-id -i id_rsa ubuntu@$node2_ip
ssh-copy-id -i id_rsa ubuntu@$node3_ip
scp id_rsa* ubuntu@$node1_ip:~/.ssh/
scp id_rsa* ubuntu@$node2_ip:~/.ssh/
scp id_rsa* ubuntu@$node3_ip:~/.ssh/

#######################
# Hadoop Installation #
#######################


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
ssh ubuntu@$node1_ip 'echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> ~/hadoop/etc/hadoop/hadoop-env.sh'
ssh ubuntu@$node2_ip 'echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> ~/hadoop/etc/hadoop/hadoop-env.sh'
ssh ubuntu@$node3_ip 'echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64" >> ~/hadoop/etc/hadoop/hadoop-env.sh'

# move hadoop to /usr/local/hadoop
ssh ubuntu@$node1_ip "sudo mv hadoop /usr/local/hadoop"
ssh ubuntu@$node2_ip "sudo mv hadoop /usr/local/hadoop"
ssh ubuntu@$node3_ip "sudo mv hadoop /usr/local/hadoop"

# configure PATH and JAVA_HOME environment variables
ssh ubuntu@$node1_ip 'echo "PATH="/usr/local/hadoop/bin:/usr/local/hadoop/sbin:$PATH"" | sudo tee -a /etc/environment'
ssh ubuntu@$node2_ip 'echo "PATH="/usr/local/hadoop/bin:/usr/local/hadoop/sbin:$PATH"" | sudo tee -a /etc/environment'
ssh ubuntu@$node3_ip 'echo "PATH="/usr/local/hadoop/bin:/usr/local/hadoop/sbin:$PATH"" | sudo tee -a /etc/environment'
ssh ubuntu@$node1_ip 'echo "JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"" | sudo tee -a /etc/environment'
ssh ubuntu@$node2_ip 'echo "JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"" | sudo tee -a /etc/environment'
ssh ubuntu@$node3_ip 'echo "JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"" | sudo tee -a /etc/environment'


mkdir hadoopconf
# create hadoop config files on local machine
cat > hadoopconf/core-site.xml <<EOF
<configuration>
<property>
<name>fs.defaultFS</name>
<value>hdfs://node1:9000</value>
</property>
</configuration>
EOF

cat > hadoopconf/hdfs-site.xml <<EOF
<configuration>
<property>
<name>dfs.namenode.name.dir</name><value>/usr/local/hadoop/data/nameNode</value>
</property>
<property>
<name>dfs.datanode.data.dir</name><value>/usr/local/hadoop/data/dataNode</value>
</property>
<property>
<name>dfs.replication</name>
<value>2</value>
</property>
</configuration>
EOF

cat > hadoopconf/workers <<EOF
node2
node3
EOF

# copy config files to all cluster nodes
scp hadoopconf/* ubuntu@$node1_ip:/usr/local/hadoop/etc/hadoop/
scp hadoopconf/* ubuntu@$node2_ip:/usr/local/hadoop/etc/hadoop/
scp hadoopconf/* ubuntu@$node3_ip:/usr/local/hadoop/etc/hadoop/

# format hdfs and startup
ssh ubuntu@$node1_ip hdfs namenode -format
ssh ubuntu@$node1_ip start-dfs.sh

######################
# Flink installation #
######################


```
