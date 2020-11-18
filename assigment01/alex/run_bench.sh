#!/usr/bin/env bash

#======================================================
# THE ULTIMATE BENCHMARKER OF ALL ULTIMATE BENCHMARKERS
# ----
# GLOBAL NOTES
# ----
# All commands will run for 60s
#======================================================

#take timestamp before chaos ensues
time_stamp=$(date +%s )

#======================================================
# BENCHMARKING PART
#======================================================

# benchmark the cpu
bench_cpu=$(sysbench --time=60 cpu run | grep "events per second")

# benchmark the memory
# special params: --memory-block-size=4KB --memory-total-size=100TB 
bench_mem=$(sysbench --time=60 memory --memory-block-size=4KB --memory-total-size=100TB run | grep 'MiB/sec')

# >>>start fileio Random Read
# special params: --file-num=1 --file-total-size=1G --file-extra-flags=direct 
# steps: prepare -> run -> cleanup
# suppresing the output of preparation and cleanup
sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=rndrd --file-extra-flags=direct prepare  > /dev/null

bench_io_rndrd=$(sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=rndrd --file-extra-flags=direct run | grep "read, MiB/s:")

sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=rndrd --file-extra-flags=direct cleanup  > /dev/null
# <<<end   fileio Random Read

# >>>start fileio Sequential Read
# special params: --file-num=1 --file-total-size=1G --file-extra-flags=direct
# steps: prepare -> run -> cleanup
# suppresing the output of preparation and cleanup
sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=seqrd --file-extra-flags=direct prepare  > /dev/null

bench_io_seqrd=$(sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=seqrd --file-extra-flags=direct run | grep "read, MiB/s:")

sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=seqrd --file-extra-flags=direct cleanup  > /dev/null
# <<<end   fileio Sequential Read

#======================================================
# FINAL INFO EXTRACTION
#======================================================

# extract specific numbers with ingenious regex patterns
res_cpu=$(echo $bench_cpu | grep -Po "\d*\.\d*")

# split the bench_mem into two parts at the word "transferred", keep the second part
res_mem=$(echo ${bench_mem##*transferred} | grep -Po "\d*\.\d*")

res_io_rnd=$(echo $bench_io_rndrd | grep -Po "\d*\.\d*")

res_io_seq=$(echo $bench_io_seqrd | grep -Po "\d*\.\d*")

# append all to preexisting file called something
echo $time_stamp,$res_cpu,$res_mem,$res_io_rnd,$res_io_seq