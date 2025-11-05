default:
    just --list

provision:
    sudo ./scripts/provision.sh

initialize:
    sudo ./scripts/initialize.sh

build:
    cmake quickfix -G Ninja -DHAVE_SSL=ON
    ninja -C quickfix

clean:
    ninja -C quickfix clean

nix-build-all:
    nix-build

nix-build-fstack:
    nix-build -A fstack

nix-build-fstack-examples:
    nix-build -A fstack-examples

nix-build-plain-quickfix:
    nix-build -A quickfix

helloworld: build-all
    sudo ./result/bin/ff_start -b ./result-2/bin/helloworld -c ./config.ini

stop-helloworld:
    sudo kill $(pidof helloworld) || echo "helloworld is not running"

