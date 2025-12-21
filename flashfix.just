# Configure Flashfix
configure:
    uv run conan install flashfix --build=missing

# Build Flashfix
build: configure
    cd flashfix && \
        source build/Release/generators/conanbuild.sh && \
        cmake --preset conan-release -G Ninja && \
        cmake --build --preset conan-release

# Rebuild Flashfix from scratch
full-build: configure
    cd flashfix && \
        source build/Release/generators/conanbuild.sh && \
        cmake --preset conan-release -G Ninja --fresh && \
        cmake --build --preset conan-release

# Build Flashfix release
release:
    cd flashfix && \
        conan create . --build=missing

# Run unit tests
test:
    ./flashfix/build/Release/test/ut --flashfix-config-file ./flashfix/test-util/cfg/ut.cfg --flashfix-spec-path ./flashfix/spec

# Build all nix derivations
nix-build-all:
    nix-build

# Run echo kernel bypass + microthreading example server
echo: nix-build-all
    sudo ./result-2/bin/ff_start -b ./result-4/bin/fstack-mt-echo -c ./config.ini

# Stop echo example
stop-echo:
    sudo kill $(pidof fstack-mt-echo) || echo "fstack-mt-echo is not running"
