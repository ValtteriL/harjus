#!/bin/bash
set -e
set -x

# prepare host for kernel bypass via f-stack

# set hugepage	
echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
mkdir -p /mnt/huge
mount -t hugetlbfs nodev /mnt/huge

# close ASLR; it is necessary in multiple process
echo 0 > /proc/sys/kernel/randomize_va_space

# insmod ko
modprobe uio
modprobe hwmon
modprobe /lib/modules/$(uname -r)/updates/dkms/igb_uio.ko

dpdk-devbind.py --status
ifconfig eth0 down
dpdk-devbind.py --bind=igb_uio eth0 # assuming that use 10GE NIC and eth0
