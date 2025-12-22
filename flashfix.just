# Build Flashfix
build:
    cd flashfix && \
        uv run conan build --build=missing

# Build Flashfix release
release:
    cd flashfix && \
        uv run conan create . --build=missing

# Clean Flashfix from conan cache
clean:
    cd flashfix && \
        uv run conan cache clean

# Run unit tests
test:
    ./flashfix/build/Release/test/ut --flashfix-config-file ./flashfix/test-util/cfg/ut.cfg --flashfix-spec-path ./flashfix/spec

