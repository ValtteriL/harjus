#!/bin/bash
# Install necessary build- and runtime dependencies

set -e

# Install dependencies
apt-get install -y \
    linux-headers-$(uname -r) \
    curl \
    dpdk \
    dpdk-doc \
    dpdk-kmods-dkms \
    dpdk-dev \
    libdpdk-dev \
    net-tools \
    pkg-config
