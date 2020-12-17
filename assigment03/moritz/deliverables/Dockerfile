FROM ubuntu:18.04

ADD forkbench.c /bench/forkbench.c
ADD benchmark.sh /bench/benchmark.sh

RUN apt-get -y update
RUN apt-get -y install iperf3 bc build-essential sysbench

RUN chmod +x /bench/benchmark.sh

RUN cd /bench && make forkbench

CMD cd /bench && 2>/dev/null bash benchmark.sh