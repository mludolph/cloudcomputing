# Answers

**1)**:

## CPU

The results for the CPU benchmark were as we expected.
Docker and QEMU with KVM acceleration reach almost native performance since they introduce only a small overhead by using hardware-assisted virtualization.
QEMU without KVM in comparison degrades the performance significantly to less than 10% of the native machine.
This is due to the fact that QEMU on its own emulates the whole system in software, making it extremely slow.

## Memory

For the memory test, the results were aligned with our expectations aswell.
Docker reaches almost native performance due to directly reusing the os kernel of the host, while QEMU with KVM accerelation degrades the performance by approx. 5% which can be attributed to the small overhead introduced by the hardware-assisted virtualization.
QEMU in comparison again only reaches approx. 10% of the native performance which is due to the software emulation as stated above.

## diskRand

The results for the random disk access did differ from our expectations for the Docker performance.
The docker performance exceeded the performance by approx. 30% of the native machine, which we suspect is due to some kind of caching done by the docker runtime itself.
The KVM and QEMU results follow the trends from above with QEMU without KVM degrading the performance the most.

## diskSeq

For the sequential disk access performance the results align with our expectations, where the docker container almost reaches native performance, QEMU with KVM acceleration only takes a minor performance hit and QEMU alone is terribly slow.
The caching we observed in the random disk access benchmark for docker did not have any effect in this benchmark.

## Fork

For the fork benchmark both KVM and Docker slightly degrade the performance in comparison to the native benchmark, which can again be attributed to the additional CPU overhead created by the docker runtime and virtualization for KVM.
As before, we observe the lowest performance when using QEMU without KVM which again can be attributed to the emulation without hardware-acceleration.

## Uplink

For the network uplink speed, the results also were as we expected.
The docker container's was only slightly lower than the native performance, which can be attributed to the small overhead of the docker NAT.
For KVM and QEMU the virtual network device introduces further latency, which has significant impact without hardware-assisted virtualization in the case of using QEMU without KVM.

**2)**:
The highest uplink deviation from the native machine was observed for the VM using QEMU only.
When connecting to a public iperf3 server, the host machine reached a speed of 32.8MBit/s while the QEMU VM reached a uplink speed of 33.0MBit/s.
The reason why the results from before could not be reproduced is that this time the bottleneck is the internet connection itself, since both speeds measured before (80GBit/s for native, 2GBit/s for QEMU) exceed the maximum bandwith of the internet connection (50MBit/s in this case) by a large margin.
