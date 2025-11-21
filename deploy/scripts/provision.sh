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
    direnv \
    pkg-config

# Install nix if not already installed
if ! ls /etc/bashrc.backup-before-nix >/dev/null 2>&1
then
    curl -L https://nixos.org/nix/install | sh -s -- --daemon
fi
