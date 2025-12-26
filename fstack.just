# Build Fstack release
release:
    cd flashfix/fstack && \
        uv run conan create . --build=missing --profile:all ../../conan-profile

# Clean Fstack from conan cache
clean:
    cd flashfix/fstack && \
        uv run conan cache clean