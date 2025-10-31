default:
    just --list

install-deps:
    sudo apt install dpdk dpdk-doc dpdk-kmods-dkms dpdk-dev libdpdk-dev net-tools

initialize:
    sudo ./scripts/initialize.sh

install-wsl-headers:
    sudo ./scripts/install-wsl-headers.sh

build-all:
    nix-build

build-fstack:
    nix-build -A fstack

build-fstack-examples:
    nix-build -A fstack-examples
