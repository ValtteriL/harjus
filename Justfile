# Justfile for Flashfix project
mod flashfix

# Default task: list all available tasks
default:
    just --list --unsorted

# Install build and runtime dependencies
provision:
    sudo ./deploy/scripts/provision.sh

# Initialize system for kernel bypass
initialize:
    sudo ./deploy/scripts/initialize.sh

configure:
    uv run conan install . --output-folder=build --build=missing

# Build Harjus
build: configure
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
    ninja -C build

# Clean build artifacts
clean:
    ninja -C build clean

# Run unit tests
test: build
    ctest --test-dir build/

# Build all nix derivations
nix-build-all:
    nix-build

# Build harjus release
release version:
    uv run conan create . --version={{version}} --output-folder=build --build=missing

# Format modified C/C++ sources on current branch with clang-format
fmt:
	@echo "Running clang-format on modified C/C++ files..."
	git-clang-format -f main

# Format all C/C++ sources in the flashfix directory with clang-format
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