# length of individual benchmarks in seconds set to 60
time=60

# prepare file benchmark with 1 file of size 1GB, discard output
sysbench fileio --file-num=1 --file-total-size=1GB prepare > /dev/null

# get the timestamp before the measurements are started
timestamp=$(date +%s)

# run cpu benchmark (no additional requirements stated) and match events per second using regex
cpu=$(sysbench cpu --time=$time run | grep -oP 'events per second:\s*\K[0-9]+.[0-9]+')
# run memory benchmark with block size of 4KB and total size of 100TB and match the MiB transferred using a regex
memory=$(sysbench memory --memory-block-size=4K --memory-total-size=100TB --time=$time run | grep -oP "MiB transferred \(\K[0-9]+.[0-9]+")
# run random access disk read and sequential disk read benchmarks with 1 file of size 1GB 
# and direct disk access and match the read MiB/s using a regex
rndrd=$(sysbench fileio --file-num=1 --file-test-mode=rndrd --file-total-size=1GB --file-extra-flags=direct --time=$time run | grep -oP "read, MiB\/s:\s*\K[0-9]+\.[0-9]+")
seqrd=$(sysbench fileio --file-num=1 --file-test-mode=seqrd --file-total-size=1GB --file-extra-flags=direct --time=$time run | grep -oP "read, MiB\/s:\s*\K[0-9]+\.[0-9]+")

# format all benchmarked quantities as csv
echo $timestamp,$cpu,$memory,$rndrd,$seqrd
