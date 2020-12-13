FROM ubuntu:18.04

ADD forkbench.c /bench/forkbench.c
ADD forkbench.sh /bench/forkbench.sh

RUN apt-get -y update
RUN apt-get -y install iperf3 bc build-essential

RUN chmod +x /bench/forkbench.sh

RUN cd /bench && make forkbench

CMD cd /bench && ./forkbench.sh