# Dockerfile for CI Jenkins builds
FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ninja-build \
    git \
    just \
    libdpdk-dev \
    wget \
    ca-certificates

# Install conan
RUN wget https://github.com/conan-io/conan/releases/download/2.23.0/conan-2.23.0-amd64.deb && \
    dpkg -i conan-2.23.0-amd64.deb && \
    rm conan-2.23.0-amd64.deb
