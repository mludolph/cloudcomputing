# Assignment 5

## Part 1 Local Flink
```bash
# to get flink locally
wget ftp://ftp.cc.uoc.gr/mirrors/apache/flink/flink-1.12.1/flink-1.12.1-bin-scala_2.11.tgz

tar xzvf flink-1.12.1-bin-scala_2.11.tgz
cd flink-1.12.1
./bin/start-cluster.sh

```

## Part 2 - Flink in Kubernetes
* Use the Kubernetes from the previous assignment to deploy Flink and
Hadoop on at least 3 worker nodes
* Use the Flink session cluster installation (NOT Flink job cluster).


```bash
VM1_EXTERNAL_IP=$(gcloud compute instances describe worker0 --format='get(networkInterfaces[0].accessConfigs[0].natIP)' --zone="europe-west1-b")

```

install helm
```bash
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
sudo apt-get install apt-transport-https --yes
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# add common repos
helm repo add stable https://charts.helm.sh/stable

# install hadoop
helm install \
--namespace default \
--generate-name \
--set yarn.nodeManager.resources.limits.memory=4096Mi \
--set yarn.nodeManager.replicas=1 \
stable/hadoop


```












## hadoop on help notes
NOTES:
1. You can check the status of HDFS by running this command:
   kubectl exec -n default -it hadoop-1611401457-hadoop-hdfs-nn-0 -- /usr/local/hadoop/bin/hdfs dfsadmin -report

2. You can list the yarn nodes by running this command:
   kubectl exec -n default -it hadoop-1611401457-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/yarn node -list

3. Create a port-forward to the yarn resource manager UI:
   kubectl port-forward -n default hadoop-1611401457-hadoop-yarn-rm-0 8088:8088

   Then open the ui in your browser:

   open http://localhost:8088

4. You can run included hadoop tests like this:
   kubectl exec -n default -it hadoop-1611401457-hadoop-yarn-nm-0 -- /usr/local/hadoop/bin/hadoop jar /usr/local/hadoop/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.9.0-tests.jar TestDFSIO -write -nrFiles 5 -fileSize 128MB -resFile /tmp/TestDFSIOwrite.txt

5. You can list the mapreduce jobs like this:
   kubectl exec -n default -it hadoop-1611401457-hadoop-yarn-rm-0 -- /usr/local/hadoop/bin/mapred job -list

6. This chart can also be used with the zeppelin chart
    helm install --namespace default --set hadoop.useConfigMap=true,hadoop.configMapName=hadoop-1611401457-hadoop stable/zeppelin

7. You can scale the number of yarn nodes like this:
   helm upgrade hadoop-1611401457 --set yarn.nodeManager.replicas=4 stable/hadoop

   Make sure to update the values.yaml if you want to make this permanent.
