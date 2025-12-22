# Justfile for dependencies
mod flashfix
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
    uv run conan build --build=missing -o boost/*:without_stacktrace=True --profile:all conan-profile

# Clean Harjus from conan cache
clean:
    uv run conan cache clean

# Run unit tests
test:
    ctest --preset conan-release

# Build harjus release
release version:
    uv run conan create . --version={{version}} --build=missing -o boost/*:without_stacktrace=True
