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

# Bind second NIC to DPDK (auto-detect interface name)
# Look for the second ethernet device (not enp0s3 which is the control interface)
DPDK_IFACE=$(ip link show | grep -E '^[0-9]+: enp0s' | grep -v enp0s3 | awk -F': ' '{print $2}' | head -n1)

if [ -n "$DPDK_IFACE" ] && [ -d "/sys/class/net/$DPDK_IFACE" ]; then
    echo "Binding $DPDK_IFACE to DPDK..."
    ifconfig "$DPDK_IFACE" down
    dpdk-devbind.py --bind=igb_uio "$DPDK_IFACE"
else
    echo "Warning: No second network interface found for DPDK"
fi

# show status
dpdk-devbind.py --status