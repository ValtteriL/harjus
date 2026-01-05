#!/bin/bash
# Install necessary build- and runtime dependencies

set -e

# Set shell to bash
sudo chsh -s /bin/bash vagrant

# Install dependencies
sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    git \
    just \
    libdpdk-dev \
    wget \
    ca-certificates \
    python3 \
    python-is-python3 \
    linux-headers-$(uname -r) \
    curl \
    dpdk \
    dpdk-doc \
    dpdk-kmods-dkms \
    dpdk-dev \
    libdpdk-dev \
    net-tools \
    bc
