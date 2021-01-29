# Assignment 05 - Distributed Stream processing

## Exercise 1

### Java project (Maven)

#### Project intialization (not needed after first setup)

```sh
mvn archetype:generate                             \
  -DarchetypeGroupId=org.apache.flink              \
  -DarchetypeArtifactId=flink-quickstart-java      \
  -DarchetypeVersion=1.12.0
```

#### Build JAR

```sh
mvn -f WordCount/pom.xml clean package
cp WordCount/target/WordCount-1.0.jar WordCount.jar
```

### Run flink locally

```sh
wget https://apache.mirror.digionline.de/flink/flink-1.12.1/flink-1.12.1-bin-scala_2.12.tgz
tar -xzf flink-1.12.1-bin-scala_2.12.tgz
rm flink-1.12.1-bin-scala_2.12.tgz
mv flink-1.12.1 flink

./flink/bin/start-cluster.sh
./flink/bin/flink run WordCount.jar --input tolstoy-war-and-peace.txt --output WordCountResults.txt
```


## Exercise 2 (THIS TIME USING QEMU VMS MUHAR)


```bash
#################
# Prerequisites #
################# 
 
# get IP addresses of all nodes (QEMU VMs in this case)
node1_ip=$(virsh --connect qemu:///system domifaddr instance1 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')
node2_ip=$(virsh --connect qemu:///system domifaddr instance2 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')
node3_ip=$(virsh --connect qemu:///system domifaddr instance3 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')

# generate an SSH key and exchange key between nodes so that nodes can SSH to eachother (after that ssh from each machine into every other one to add them to the known_hosts)
# we need ssh-less access from our machine to all nodes and from each node to every other node
ssh-keygen -q -t rsa -N '' -f ./id_rsa
ssh-copy-id -i id_rsa ubuntu@$node1_ip
ssh-copy-id -i id_rsa ubuntu@$node2_ip
ssh-copy-id -i id_rsa ubuntu@$node3_ip
scp id_rsa* ubuntu@$node1_ip:~/.ssh/
scp id_rsa* ubuntu@$node2_ip:~/.ssh/
scp id_rsa* ubuntu@$node3_ip:~/.ssh/

# install java on all nodes
ssh ubuntu@$node1_ip "sudo apt-get update & sudo apt-get -y install openjdk-8-jdk"
ssh ubuntu@$node2_ip "sudo apt-get update & sudo apt-get -y install openjdk-8-jdk"
ssh ubuntu@$node3_ip "sudo apt-get update & sudo apt-get -y install openjdk-8-jdk"

# OPTIONAL: test java installation
ssh ubuntu@$node1_ip "java -version"
ssh ubuntu@$node2_ip "java -version"
ssh ubuntu@$node3_ip "java -version"


#######################
# Hadoop Installation #
#######################

# download, unpack and rename the directory (for brevity) on all nodes
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

# create directory to put all configuration files into (on local machine)
mkdir hadoopconf

# create 
cat > hadoopconf/core-site.xml <<EOF
<configuration>
<property>
<name>fs.defaultFS</name>
<value>hdfs://node1:9000</value>
</property>
</configuration>
EOF

# configure hdfs properties
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

# configure worker nodes (all in this case)
cat > hadoopconf/workers <<EOF
node1
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

# download flink, unzip and move to rename the directory (for brevity) on each node
ssh ubuntu@$node1_ip "wget -q https://apache.mirror.digionline.de/flink/flink-1.12.1/flink-1.12.1-bin-scala_2.12.tgz && tar -xzf flink-1.12.1-bin-scala_2.12.tgz && mv flink-1.12.1 flink"
ssh ubuntu@$node2_ip "wget -q https://apache.mirror.digionline.de/flink/flink-1.12.1/flink-1.12.1-bin-scala_2.12.tgz && tar -xzf flink-1.12.1-bin-scala_2.12.tgz && mv flink-1.12.1 flink"
ssh ubuntu@$node3_ip "wget -q https://apache.mirror.digionline.de/flink/flink-1.12.1/flink-1.12.1-bin-scala_2.12.tgz && tar -xzf flink-1.12.1-bin-scala_2.12.tgz && mv flink-1.12.1 flink"

# add the configuration key for the master node to configuration on each node
ssh ubuntu@$node1_ip 'echo "jobmanager.rpc.address: node1" >> flink/conf/flink-conf.yaml'
ssh ubuntu@$node2_ip 'echo "jobmanager.rpc.address: node1" >> flink/conf/flink-conf.yaml'
ssh ubuntu@$node3_ip 'echo "jobmanager.rpc.address: node1" >> flink/conf/flink-conf.yaml'

# add the hadoop configuration directory to the config for each node
ssh ubuntu@$node1_ip 'echo "env.hadoop.conf.dir: /usr/local/hadoop/etc/hadoop" >> flink/conf/flink-conf.yaml'
ssh ubuntu@$node2_ip 'echo "env.hadoop.conf.dir: /usr/local/hadoop/etc/hadoop" >> flink/conf/flink-conf.yaml'
ssh ubuntu@$node3_ip 'echo "env.hadoop.conf.dir: /usr/local/hadoop/etc/hadoop" >> flink/conf/flink-conf.yaml'

ssh ubuntu@$node1_ip 'sudo mv flink /usr/local/flink'
ssh ubuntu@$node2_ip 'sudo mv flink /usr/local/flink'
ssh ubuntu@$node3_ip 'sudo mv flink /usr/local/flink'

# add required environment variables
ssh ubuntu@$node1_ip 'echo "HADOOP_CLASSPATH=$(hadoop classpath)" | sudo tee -a /etc/environment'
ssh ubuntu@$node2_ip 'echo "HADOOP_CLASSPATH=$(hadoop classpath)" | sudo tee -a /etc/environment'
ssh ubuntu@$node3_ip 'echo "HADOOP_CLASSPATH=$(hadoop classpath)" | sudo tee -a /etc/environment'

# add flink to path variable
ssh ubuntu@$node1_ip 'echo "PATH="/usr/local/flink/bin:$PATH"" | sudo tee -a /etc/environment'
ssh ubuntu@$node2_ip 'echo "PATH="/usr/local/flink/bin:$PATH"" | sudo tee -a /etc/environment'
ssh ubuntu@$node3_ip 'echo "PATH="/usr/local/flink/bin:$PATH"" | sudo tee -a /etc/environment'

# create configuration for flink masters & workers
mkdir flinkconf
cat > flinkconf/master <<EOF
node1
EOF

cat > flinkconf/workers <<EOF
node1
node2
node3
EOF

# copy worker/master configuration to all nodes
scp flinkconf/* ubuntu@$node1_ip:/usr/local/flink/conf
scp flinkconf/* ubuntu@$node2_ip:/usr/local/flink/conf
scp flinkconf/* ubuntu@$node3_ip:/usr/local/flink/conf

# start the flink cluster
ssh ubuntu@$node1_ip start-cluster.sh
```

### Run WordCount example on Cluster

```bash
# copy jar and input file to master node
scp {WordCount.jar,tolstoy-war-and-peace.txt} ubuntu@$node1_ip:~

# put input file to hdfs
hdfs dfs -put tolstoy-war-and-peace.txt /

# run WordCount on cluster
flink run WordCount.jar --input "hdfs://node1:9000/tolstoy-war-and-peace.txt" --output "hdfs://node1:9000/WordCountResults.txt"

# get output from hdfs
hdfs dfs -get WordCountResults.txt
```
