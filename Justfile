# Justfile for dependencies
mod fstack

# Default task: list all available tasks
default:
    just --list --unsorted

# Build Harjus in debug mode
build:
    conan build --build=missing --profile:all conan-profile

# Build Harjus release
build-release architecture = "native":
    conan build --build=missing --profile:all conan-profile --settings build_type=Release -c tools.build:cxxflags="['-march={{architecture}}','-mtune={{architecture}}']"

# Run unit tests
test:
    ctest --preset conan-debug

# Run debug build
run:
    sudo ./build/Debug/flashfix/start.sh -b ./build/Debug/src/harjus -c ./build/Debug/flashfix/config.ini

# Run release build
run-release:
    sudo ./build/Release/flashfix/start.sh -b ./build/Release/src/harjus -c ./build/Release/flashfix/config.ini
