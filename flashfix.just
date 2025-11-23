# Build Flashfix
build:
    cmake -B flashfix-build flashfix -G Ninja -DCMAKE_BUILD_TYPE=Debug
    ninja -C flashfix-build

# Clean build artifacts
clean:
    ninja -C flashfix-build clean

# Run unit tests
test:
    ./flashfix-build/test/ut --flashfix-config-file ./flashfix/test-util/cfg/ut.cfg --flashfix-spec-path ./flashfix/spec

# Build all nix derivations
nix-build-all:
    nix-build

# Run helloworld kernel bypass example server
helloworld: nix-build-all
    sudo ./result-2/bin/ff_start -b ./result-3/bin/helloworld -c ./config.ini

# Stop helloworld example
stop-helloworld:
    sudo kill $(pidof helloworld) || echo "helloworld is not running"

# Run echo kernel bypass + microthreading example server
echo: nix-build-all
    sudo ./result-2/bin/ff_start -b ./result-4/bin/fstack-mt-echo -c ./config.ini

# Stop echo example
stop-echo:
    sudo kill $(pidof fstack-mt-echo) || echo "fstack-mt-echo is not running"
