# Build Fstack release
release:
    cd flashfix/fstack && \
        conan create . --build=missing --profile:all ../../conan-profile

# Clean Fstack from conan cache
clean:
    cd flashfix/fstack && \
        conan cache clean