# Dockerfile for CI Jenkins builds
FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    just \
    libdpdk-dev \
    curl

# Install uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

