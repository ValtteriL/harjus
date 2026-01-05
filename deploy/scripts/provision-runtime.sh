#!/bin/bash
# Install runtime dependencies (DPDK, network tools, etc.)

set -e

# Install runtime dependencies
sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
    dpdk \
    dpdk-doc \
    dpdk-kmods-dkms \
    net-tools \
    bc
