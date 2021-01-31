FROM ubuntu:18.04
# Start from the Ubuntu 18.04 image

# Add our implementation of the forkbench and the benchmarking script to the image
ADD forkbench.c /bench/forkbench.c
ADD benchmark.sh /bench/benchmark.sh

# Update repositories
RUN apt-get -y update
# Install build-essential (for make), sysbench, bc and iperf3 for benchmarking
RUN apt-get -y install iperf3 bc build-essential sysbench

# Make benchmarking script executable
RUN chmod +x /bench/benchmark.sh

# Compile forkbenchs
RUN cd /bench && make forkbench

# Run benchmark script with stderr redirected on startup
CMD cd /bench && 2>/dev/null bash benchmark.sh