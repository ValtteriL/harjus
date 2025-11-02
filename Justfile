default:
    just --list

initialize:
    sudo ./scripts/initialize.sh

build-all:
    nix-build

build-fstack:
    nix-build -A fstack

build-fstack-examples:
    nix-build -A fstack-examples
