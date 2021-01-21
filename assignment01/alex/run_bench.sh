#!/usr/bin/env bash

#======================================================
# THE ULTIMATE BENCHMARKER OF ALL ULTIMATE BENCHMARKERS
# ----
# GLOBAL NOTES
# ----
# All commands will be executed for 60s
#======================================================

# take Unix timestamp before everything is executed
time_stamp=$(date +%s )

# benchmark the cpu
bench_cpu=$(sysbench --time=60 cpu run | grep "events per second")

# benchmark the memory
# special params: --memory-block-size=4KB --memory-total-size=100TB 
bench_mem=$(sysbench --time=60 memory --memory-block-size=4KB --memory-total-size=100TB run | grep 'MiB/sec')

# >>>start benchmark fileio Random Read
# special params: --file-num=1 --file-total-size=1G --file-extra-flags=direct 
# steps: prepare -> run -> cleanup
sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=rndrd --file-extra-flags=direct prepare  > /dev/null
bench_io_rndrd=$(sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=rndrd --file-extra-flags=direct run | grep "read, MiB/s:")
sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=rndrd --file-extra-flags=direct cleanup  > /dev/null
# >>>end   fileio Random Read

# >>>start benchmark fileio Sequential Read
# special params: --file-num=1 --file-total-size=1G --file-extra-flags=direct
# steps: prepare -> run -> cleanup
sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=seqrd --file-extra-flags=direct prepare  > /dev/null
bench_io_seqrd=$(sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=seqrd --file-extra-flags=direct run | grep "read, MiB/s:")
sysbench fileio --time=60 --file-num=1 --file-total-size=1G --file-test-mode=seqrd --file-extra-flags=direct cleanup  > /dev/null
# >>>end   fileio Sequential Read

# extract specific numbers with regex patterns
res_cpu=$(echo $bench_cpu | grep -Po "\d*\.\d*")
# ${bench_mem##*transferred} splits bench_mem in two parts and keeps the latter one
res_mem=$(echo ${bench_mem##*transferred} | grep -Po "\d*\.\d*")
res_io_rnd=$(echo $bench_io_rndrd | grep -Po "\d*\.\d*")
res_io_seq=$(echo $bench_io_seqrd | grep -Po "\d*\.\d*")

# output our results in given order and format
echo $time_stamp,$res_cpu,$res_mem,$res_io_rnd,$res_io_seq