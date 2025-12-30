#!/bin/bash
set -e
set -x

# prepare host for kernel bypass via f-stack

# Set hugepages
echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
mkdir -p /mnt/huge
mount -t hugetlbfs nodev /mnt/huge

# close ASLR; it is necessary in multiple process
echo 0 > /proc/sys/kernel/randomize_va_space

# load kernel modules
modprobe uio
modprobe hwmon
modprobe igb_uio

# take over enp0s8 for f-stack
if [ -d /sys/class/net/enp0s8 ]; then
    ifconfig enp0s8 down
    dpdk-devbind.py --bind=igb_uio enp0s8

    # to undo, run:
    # dpdk-devbind.py --bind=virtio-pci 00:03.0
    # ifconfig enp0s8 up
fi

# show status
dpdk-devbind.py --status