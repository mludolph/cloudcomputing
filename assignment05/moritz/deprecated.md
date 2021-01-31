
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
