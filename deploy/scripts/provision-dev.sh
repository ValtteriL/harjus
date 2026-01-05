#!/bin/bash
# Install development dependencies (build tools, compilers, etc.)

set -e

# Set shell to bash
sudo chsh -s /bin/bash vagrant

# Install development dependencies
sudo apt-get update && \
    sudo apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    git \
    just \
    wget \
    ca-certificates \
    python3 \
    python-is-python3 \
    linux-headers-$(uname -r) \
    libdpdk-dev \
    dpdk-dev \
    curl

# Install conan
wget https://github.com/conan-io/conan/releases/download/2.23.0/conan-2.23.0-amd64.deb && \
    sudo dpkg -i conan-2.23.0-amd64.deb && \
    rm conan-2.23.0-amd64.deb
