# Justfile for dependencies
mod fstack

# Default task: list all available tasks
default:
    just --list --unsorted

# Install build and runtime dependencies
provision:
    sudo ./deploy/scripts/provision.sh

# Initialize system for kernel bypass
initialize:
    sudo ./deploy/scripts/initialize.sh

# Build Harjus
build:
    uv run conan build --build=missing --profile:all conan-profile

# Clean Harjus from conan cache
clean:
    uv run conan cache clean

# Run unit tests
test:
    ctest --preset conan-debug

# Run flashfix unit tests
test-flashfix:
    ./build/Debug/test/ut --flashfix-config-file ./flashfix/test-util/cfg/ut.cfg --flashfix-spec-path ./flashfix/spec

# Build harjus release
release version:
    uv run conan create . --version={{version}} --build=missing --profile:all conan-profile
