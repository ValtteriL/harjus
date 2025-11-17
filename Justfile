default:
    just --list

provision:
    sudo ./scripts/provision.sh

initialize:
    sudo ./scripts/initialize.sh

# Build Fast-QuickFIX
build:
    cmake -B build quickfix -G Ninja -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=Debug
    ninja -C build

# Clean build artifacts
clean:
    ninja -C build clean

# Run unit tests
test:
    ./build/src/C++/test/ut --quickfix-config-file ./quickfix/test/cfg/ut.cfg --quickfix-spec-path ./quickfix/spec

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

# Format modified C/C++ sources on current branch with clang-format
fmt:
	@echo "Running clang-format on modified C/C++ files..."
	git-clang-format -f main

# Format all C/C++ sources in the quickfix directory with clang-format
fmt-full:
    @echo "Running clang-format on all C/C++ files..."
    clang-format -i `find . -name "*.cpp" -or -name "*.hpp" -or -name "*.c" -or -name "*.h"`

# Lint C/C++ sources with essential rules
lint:
    echo "Running clang-tidy with essential rules..."
    run-clang-tidy -p build -fix -quiet -j$(nproc)

# Lint C/C++ sources with comprehensive rules
lint-full:
    echo "Running clang-tidy with .clang-tidy.full..."
    run-clang-tidy -p build -config-file .clang-tidy.full -fix -quiet -j$(nproc)