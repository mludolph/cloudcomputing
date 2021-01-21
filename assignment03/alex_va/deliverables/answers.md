

## Memory
The memory performance for the native, docker and KVM machines is very similar, altough degrating in that order. The worst performance is observed for the QEMU machine. These results are alligned to our expectations and the characteristics of each machine. Both Docker and KVM directly use the system's kernel, but KVM is heavier bu default, thus the worst performance.


## Uplink

We can see that the native machine outperforms all others, followed by Docker, KVM and last QEMU. The latency of Docker is due to the Docker NAT. For QEMU-KVM and pure QEMU, the latency is probably due to the way each system interacts with the hosts physical network drivers.