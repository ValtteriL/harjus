# Dependency recipes
mod fstack

# Deployment recipes
mod deploy

# Default task: list all available tasks
default:
    just --list --unsorted

# Build in debug binary
build:
    conan build --build=missing --profile:all conan-profile

# check valid architecture options with `gcc --target-help`
# Build release binary
build-release architecture = "native":
    conan build --build=missing --profile:all conan-profile --settings build_type=Release -c tools.build:cxxflags="['-march={{architecture}}','-mtune={{architecture}}']" -c tools.cmake.cmaketoolchain:extra_variables="{'HARJUS_TESTS':'OFF'}"

# Run unit tests
test:
    ctest --preset conan-debug

# Run debug build
run:
    sudo ./flashfix/start.sh -b ./build/Debug/src/harjus -c ./flashfix/config.ini

# Run release build
run-release:
    sudo ./flashfix/start.sh -b ./build/Release/src/harjus -c ./flashfix/config.ini

# Package a release into tar.gz for distribution
package:
    cpack --config build/Release/CPackConfig.cmake
    ls -l dist
