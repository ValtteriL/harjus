default:
    just --list

install-deps:
    sudo apt install dpdk dpdk-doc dpdk-kmods-dkms dpdk-dev libdpdk-dev

build-fstack:
    cd lib \
    && PKG_CONFIG_PATH_FOR_TARGET=/usr/lib/x86_64-linux-gnu/pkgconfig:$PKG_CONFIG_PATH_FOR_TARGET make
