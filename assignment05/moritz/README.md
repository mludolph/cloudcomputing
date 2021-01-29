# Assignment 05 - Distributed Stream processing

## Exercise 1

### Setup local flink installation

Guide: [https://flink.apache.org/downloads.html](https://flink.apache.org/downloads.html)

```sh
wget https://apache.mirror.digionline.de/flink/flink-1.12.1/flink-1.12.1-bin-scala_2.12.tgz
tar -xzf flink-1.12.1-bin-scala_2.12.tgz
rm flink-1.12.1-bin-scala_2.12.tgz
mv flink-1.12.1 flink


./flink/bin/start-cluster.sh
```

### Java project (Maven)

#### Initial Project Setup

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

#### Run on flink

```sh
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


### DEPRECATED

#### SSH into QEMU VM (one of the kubernetes nodes)

```bash 
# get the IP of the first node (necessary because kubectl is not available externally)
node1_ip=$(virsh --connect qemu:///system domifaddr instance1 | awk 'NR==3{print $4; exit}' | grep -o '^[^/]*')
ssh ubuntu@$node1_ip

# install java to use flink
sudo apt update
sudo apt install default-jre
sudo apt install openjdk-11-jdk
```

#### Install Helm

```bash
# download the helm installation script
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
# add execute permissions to the installation script
chmod 700 get_helm.sh
# run the installation script
./get_helm.sh

# add the stable repository to helm
helm repo add stable https://charts.helm.sh/stable
```


#### Deploy Hadoop on k8s

```bash
# deploy hadoop using the helmchart from the stable/hadoop
helm install hadoop \
--namespace default \
--set yarn.nodeManager.resources.limits.memory=2048Mi \
--set yarn.nodeManager.replicas=1 \
stable/hadoop
```

#### Deploy Flink on k8s

```bash 
# create the YAML files flink-configuration-configmap.yaml, jobmanager-service.yaml, jobmanager-session-deployment.yaml and taskmanager-session-deployment.yaml as stated on https://ci.apache.org/projects/flink/flink-docs-release-1.12/deployment/resource-providers/standalone/kubernetes.html
kubectl create -f flink-configuration-configmap.yaml
kubectl create -f jobmanager-service.yaml
# Create the deployments for the cluster
kubectl create -f jobmanager-session-deployment.yaml
kubectl create -f taskmanager-session-deployment.yaml

# since new versions of 

```

#### Start Flink job

```bash
# get the pod name of a yarn pod
POD_NAME=$(kubectl get pods | grep yarn-nm | awk '{print $1}')
# copy the input file to the pod
kubectl cp tolstoy-war-and-peace.txt "${POD_NAME}":/home
# put the input file onto hdfs using the pod
kubectl exec -it "${POD_NAME}" -- hdfs dfs -put /home/tolstoy-war-and-peace.txt /

FLINK_POD_NAME=$(kubectl get pods | grep flink-jobmanager | awk '{print $1}')
kubectl port-forward ${FLINK_POD_NAME} 8081:8081 &

NAMENODE_SVC_NAME=$(kubectl get pods | grep "yarn-nm" | awk '{print $1}')
./flink/bin/flink run -m localhost:8081 WordCount.jar --input "hdfs://${NAMENODE_SVC_NAME}:8088/tolstoy-war-and-peace.txt" --output "hdfs://${NAMENODE_SVC_NAME}:8088/output.txt"
```

```
kubectl delete -f jobmanager-service.yaml
kubectl delete -f flink-configuration-configmap.yaml
kubectl delete -f taskmanager-session-deployment.yaml
kubectl delete -f jobmanager-session-deployment.yaml
```
