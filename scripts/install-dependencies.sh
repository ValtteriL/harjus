#!/bin/bash
# Install necessary build- and runtime dependencies

set -e

# Update package list
apt-get update

# Install dependencies
apt-get install -y \
    linux-headers-$(uname -r) \
    curl \
    dpdk \
    dpdk-doc \
    dpdk-kmods-dkms \
    dpdk-dev \
    libdpdk-dev \
    net-tools

# Install nix
curl -L https://nixos.org/nix/install | sh -s -- --daemon

