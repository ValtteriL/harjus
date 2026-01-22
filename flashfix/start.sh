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

if ! type "bc" > /dev/null 2>&1; then
    echo "please install bc"
    exit
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

# Kill all child processes on SIGINT or SIGTERM
trap 'pkill -P $$; exit' SIGINT SIGTERM

allcmask0x=`cat ${conf}|grep lcore_mask|awk -F '=' '{print $2}'`
((allcmask=16#$allcmask0x))

num_procs=0
PROCESSOR=$(grep 'processor' /proc/cpuinfo |sort |uniq |wc -l)
for((i=0;i<${PROCESSOR};++i))
do
    mask=`echo "2^$i"|bc`
    ((result=${allcmask} & ${mask}))
    if [ ${result} != 0 ]
    then
        ((num_procs++));
    fi
done

for((proc_id=0; proc_id<${num_procs}; ++proc_id))
do
    if ((proc_id == 0))
    then
        echo "${bin} --conf ${conf} --proc-type=primary --proc-id=${proc_id} ${others}"
        ${bin} --conf ${conf} --proc-type=primary --proc-id=${proc_id} ${others} &
        primary_pid=$!
        sleep 5
    else
        echo "${bin} --conf ${conf} --proc-type=secondary --proc-id=${proc_id} ${others}"
        ${bin} --conf ${conf} --proc-type=secondary --proc-id=${proc_id} ${others} &
    fi
done

# wait for primary process and capture its exit code
wait ${primary_pid}
exit_code=$?

# kill any remaining secondary processes
pkill -P $$ 2>/dev/null || true

exit ${exit_code}
