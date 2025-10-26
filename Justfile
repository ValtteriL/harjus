default:
    just --list

build-dpdk:
    cd dpdk \
    && meson setup -Denable_kmods=true -Ddisable_libs=flow_classify -Dkernel_dir="$KERNEL_DIR" build \
    && ninja -C build \
    && ninja -C build install
