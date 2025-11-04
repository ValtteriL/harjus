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
modprobe igb_uio

# take over ens19 for f-stack
if [ -d /sys/class/net/ens19 ]; then
    ifconfig ens19 down
    dpdk-devbind.py --bind=igb_uio ens19
fi
# to undo, run:
# dpdk-devbind.py --bind=virtio-pci 00:13.0
# ifconfig ens19 up

# show status
dpdk-devbind.py --status