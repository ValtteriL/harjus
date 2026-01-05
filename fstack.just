# Build Fstack release
release:
    cd flashfix/fstack && \
        conan create . --build=missing --profile:all ../../conan-profile
