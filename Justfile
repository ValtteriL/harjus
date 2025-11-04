default:
    just --list

provision:
    sudo ./scripts/provision.sh

initialize:
    sudo ./scripts/initialize.sh

helloworld:
    sudo ./result/bin/ff_start -b ./result-2/bin/helloworld -c ./myconfig.ini

stop-helloworld:
    sudo kill $(pidof helloworld) || echo "helloworld is not running"

build-all:
    nix-build

build-fstack:
    nix-build -A fstack

build-fstack-examples:
    nix-build -A fstack-examples
