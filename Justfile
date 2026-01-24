# Justfile for dependencies
mod fstack

# Default task: list all available tasks
default:
    just --list --unsorted

# Build Harjus in debug mode
build:
    conan build --build=missing --profile:all conan-profile

# check valid architecture options with `gcc --target-help`
# Build Harjus release
build-release architecture = "native":
    conan build --build=missing --profile:all conan-profile --settings build_type=Release -c tools.build:cxxflags="['-march={{architecture}}','-mtune={{architecture}}']" -c tools.cmake.cmake_args="['-DHARJUS_TESTS=OFF']"

# Run unit tests
test:
    ctest --preset conan-debug

# Run debug build
run:
    sudo ./flashfix/start.sh -b ./build/Debug/src/harjus -c ./flashfix/config.ini

# Run release build
run-release:
    sudo ./flashfix/start.sh -b ./build/Release/src/harjus -c ./flashfix/config.ini

# Install debug build to a directory (default: ./dist)
install prefix="./dist":
    cmake --install build/Debug --prefix {{prefix}}

# Install release build to a directory (default: ./dist)
install-release prefix="./dist":
    cmake --install build/Release --prefix {{prefix}}
