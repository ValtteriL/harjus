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

test:
    ./quickfix/src/C++/test/ut --quickfix-config-file ./quickfix/test/cfg/ut.cfg --quickfix-spec-path ./quickfix/spec

nix-build-all:
    nix-build

nix-build-fstack:
    nix-build -A fstack

nix-build-fstack-mt:
    nix-build -A fstack-mt

nix-build-fstack-examples:
    nix-build -A fstack-examples

nix-build-plain-quickfix:
    nix-build -A quickfix

helloworld: nix-build-all
    sudo ./result-2/bin/ff_start -b ./result-3/bin/helloworld -c ./config.ini

stop-helloworld:
    sudo kill $(pidof helloworld) || echo "helloworld is not running"

echo: nix-build-all
    sudo ./result-2/bin/ff_start -b ./result-4/bin/fstack-mt-echo -c ./config.ini

stop-echo:
    sudo kill $(pidof fstack-mt-echo) || echo "fstack-mt-echo is not running"