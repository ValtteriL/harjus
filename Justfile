default:
    just --list

install-deps:
    sudo apt install dpdk dpdk-doc dpdk-kmods-dkms dpdk-dev libdpdk-dev

initialize:
    sudo ./scripts/initialize.sh

build-all:
    nix-build

build-fstack:
    nix-build -A fstack

build-fstack-examples:
    nix-build -A fstack-examples