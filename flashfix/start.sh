#!/bin/bash

function usage() {
    echo "F-Stack app start tool"
    echo "Options:"
    echo " -c [conf]                Path of config file"
    echo " -b [N]                   Path of binary"
    echo " -o [N]                   Other ARGs for app"
    echo " -h                       show this help"
    exit
}

#conf=config.ini
#bin=./example/helloworld

while getopts "c:b:o:h" args
do
    case $args in
         c)
            conf=$OPTARG
            ;;
         b)
            bin=$OPTARG
            ;;
         o)
            others=$OPTARG
            ;;
         h)
            usage
            exit 0
            ;;
    esac
done

# ensure run as root
if [ "$EUID" -ne 0 ]; then
    echo "please run as root"
    exit 1
fi

# if bin not defined, exit
if [ -z "${bin}" ]; then
    echo "please specify binary path with -b"
    usage
    exit 1
fi

# if conf not defined, exit
if [ -z "${conf}" ]; then
    echo "please specify config path with -c"
    usage
    exit 1
fi

# Cleanup previous instances
app_name=$(basename ${bin})
echo "Cleaning up previous instances of ${app_name}..."
pkill -x ${app_name} || true
sleep 2
pkill -9 -x ${app_name} || true

# Clean up DPDK/F-Stack artifacts
echo "Cleaning up DPDK/F-Stack artifacts..."
rm -rf /var/run/dpdk/*
rm -f /var/run/.rte_config
rm -f /var/run/.rte_hugepage_info
# Clean hugepages
rm -f /mnt/huge/*

exec ${bin} --conf ${conf} --proc-type=primary --proc-id=0 ${others}
