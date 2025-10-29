#!/bin/bash
set -e
set -x

# build WSL kernel, install with headers

sudo apt install build-essential flex bison dwarves libssl-dev libelf-dev cpio qemu-utils

cd wsl-kernel

git clone https://github.com/microsoft/WSL2-Linux-Kernel.git

cd WSL2-Linux-Kernel

git checkout linux-msft-wsl-6.6.87.2

make -j$(nproc) KCONFIG_CONFIG=Microsoft/config-wsl && make INSTALL_MOD_PATH="$PWD/modules" modules_install

# TODO: install, configure wsl to use this kernel