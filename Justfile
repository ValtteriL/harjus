# Justfile for dependencies
mod fstack

# Default task: list all available tasks
default:
    just --list --unsorted

# Build Harjus in debug mode
build:
    conan build --build=missing --profile:all conan-profile

# Build Harjus release
build-release:
    conan build --build=missing --profile:all conan-profile --settings build_type=Release

# Run unit tests
test:
    ctest --preset conan-debug

# Run debug build
run:
    sudo ./flashfix/start.sh -b ./build/Debug/src/harjus -c ./flashfix/config.ini

# Run release build
run-release:
    sudo ./flashfix/start.sh -b ./build/Release/src/harjus -c ./flashfix/config.ini

# Run flashfix unit tests
test-flashfix:
    ./build/Debug/flashfix/test/ut --flashfix-config-file ./flashfix/test-util/cfg/ut.cfg --flashfix-spec-path ./flashfix/spec

# Build harjus release
release version:
    conan create . --version={{version}} --build=missing --profile:all conan-profile
