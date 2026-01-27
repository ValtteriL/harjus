#!/bin/bash
set -e
set -x

# prepare host for kernel bypass via f-stack

# ensure run as root
if [ "$EUID" -ne 0 ]; then
    echo "please run as root"
    exit 1
fi

# Get DPDK interface from argument
if [ -z "$1" ]; then
    echo "Error: DPDK interface name is required"
    echo "Usage: $0 <interface_name>"
    exit 1
fi
DPDK_IFACE="$1"

# Set hugepages
echo 1024 > /sys/kernel/mm/hugepages/hugepages-2048kB/nr_hugepages
mkdir -p /mnt/huge
mount -t hugetlbfs nodev /mnt/huge

# close ASLR; it is necessary in multiple process
echo 0 > /proc/sys/kernel/randomize_va_space

# load kernel modules
modprobe uio
modprobe igb_uio

# Bind NIC to DPDK
if [ -d "/sys/class/net/$DPDK_IFACE" ]; then
    echo "Binding $DPDK_IFACE to DPDK..."
    ifconfig "$DPDK_IFACE" down
    dpdk-devbind.py --bind=igb_uio "$DPDK_IFACE"
else
    echo "Error: Interface $DPDK_IFACE not found"
    exit 1
fi

# show status
dpdk-devbind.py --status