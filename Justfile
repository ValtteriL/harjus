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

helloworld: build-all
    sudo ./result/bin/ff_start -b ./result-2/bin/helloworld -c ./config.ini

stop-helloworld:
    sudo kill $(pidof helloworld) || echo "helloworld is not running"

