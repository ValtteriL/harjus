default:
    just --list

provision:
    sudo ./scripts/provision.sh

initialize:
    sudo ./scripts/initialize.sh

# Build Fast-QuickFIX
build:
    cmake quickfix -G Ninja -DHAVE_SSL=ON -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
    ninja -C quickfix

# Clean build artifacts
clean:
    ninja -C quickfix clean

# Run unit tests
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

nix-build-fstack-tools:
    nix-build -A fstack-tools

nix-build-plain-quickfix:
    nix-build -A quickfix

nix-build-run-clang-tidy:
    nix-build -A run-clang-tidy

nix-build-git-clang-format:
    nix-build -A git-clang-format

helloworld: nix-build-all
    sudo ./result-2/bin/ff_start -b ./result-3/bin/helloworld -c ./config.ini

stop-helloworld:
    sudo kill $(pidof helloworld) || echo "helloworld is not running"

echo: nix-build-all
    sudo ./result-2/bin/ff_start -b ./result-4/bin/fstack-mt-echo -c ./config.ini

stop-echo:
    sudo kill $(pidof fstack-mt-echo) || echo "fstack-mt-echo is not running"

# Format tracked C/C++ sources with clang-format
fmt:
	@echo "Running clang-format on tracked C/C++ files..."
	git-clang-format -f

# Lint built C/C++ sources with clang-tidy
lint:
    echo "Running clang-tidy on tracked C/C++ files..."
    run-clang-tidy -p build -use-color -fix -quiet -j$(nproc)