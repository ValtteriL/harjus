# Build Fstack release
release:
    cd flashfix/fstack && \
        uv run conan create . --build=missing
