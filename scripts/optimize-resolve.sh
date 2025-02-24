#!/bin/bash
# determine ip for hostname with lowest rtt
# requires `dig` and `nping` - dig already installed on amazon linux
# sudo dnf install nmap
# usage: cat hosts.txt | sudo ./optimize-resolve.sh <number of nping probes>
# hosts.txt contains hostname and port separated by space

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <number of nping probes>"
    exit 1
fi

NUM_PROBES=$1
echo "Using $NUM_PROBES probes"

while read line
do
        HOST=`echo $line| awk '{print $1}'`
        PORT=`echo $line| awk '{print $2}'`
        #echo "line = $line | hostname = $HOST | port = $PORT"
        BEST_IP=$(for ip in `dig +short $HOST`; do
                avg_rtt=`nping -c "$NUM_PROBES" --tcp -p "$PORT" "$ip" |grep "Avg rtt" |awk '{print $11}'`
                echo "DEBUG: $HOST $ip $avg_rtt" >&2
                echo "$ip $avg_rtt"
        done|sort -k2 -n | head -n1|awk '{print $1}')

        echo "IP with lowest rtt for $HOST is $BEST_IP"
done < "/dev/stdin"
