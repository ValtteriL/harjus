# Build Fstack
build:
    cd flashfix/fstack && \
        uv run conan create . --build=missing
