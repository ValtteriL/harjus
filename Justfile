default:
    just --list

provision:
    sudo ./scripts/provision.sh

initialize:
    sudo ./scripts/initialize.sh

build-all:
    nix-build

build-fstack:
    nix-build -A fstack

build-fstack-examples:
    nix-build -A fstack-examples
