# Default task: list all available tasks
default:
    just --list fstack --unsorted

# Build Fstack release
release:
    cd flashfix/fstack && \
        conan create . --build=missing --profile:all ../../conan-profile
