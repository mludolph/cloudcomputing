# Assignment 05 - Distributed Stream processing

## Exercise 1

### Setup local flink installation

Guide: [https://flink.apache.org/downloads.html](https://flink.apache.org/downloads.html)

```sh
wget https://apache.mirror.digionline.de/flink/flink-1.12.1/flink-1.12.1-bin-scala_2.12.tgz
tar -xzf flink-1.12.1-bin-scala_2.12.tgz
rm flink-1.12.1-bin-scala_2.12.tgz

cd flink-1.12.1

./bin/start-cluster.sh
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
./flink-1.12.1/bin/flink run WordCount.jar --input tolstoy-war-and-peace.txt --output WordCountResults.txt
```
