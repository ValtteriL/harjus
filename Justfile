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
    uv run conan install . --build=missing

# Build Harjus
build: configure
    cmake --preset conan-release -G Ninja
    cmake --build --preset conan-release

# Rebuild Harjus from scratch
full-build: configure
    cmake --preset conan-release -G Ninja --fresh
    cmake --build --preset conan-release

# Run unit tests
test: build
    ctest --preset conan-release

# Build all nix derivations
nix-build-all:
    nix-build

# Build harjus release
release version:
    uv run conan create . --version={{version}} --build=missing

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