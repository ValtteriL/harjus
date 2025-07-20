# Network performance

Find optimal AZID to put EC2 instances in.

Mapping of AZs to AZIDs:

```bash
aws ec2 describe-availability-zones --region ap-northeast-1 \
  --query "AvailabilityZones[].{Name:ZoneName, Id:ZoneId}" \
  --output table
# ----------------------------------
# |    DescribeAvailabilityZones   |
# +------------+-------------------+
# |     Id     |       Name        |
# +------------+-------------------+
# |  apne1-az4 |  ap-northeast-1a  |
# |  apne1-az1 |  ap-northeast-1c  |
# |  apne1-az2 |  ap-northeast-1d  |
# +------------+-------------------+
```

Latency measurement script

```bash
export NUM_PROBES=100
export port=9000
export host=fix-md.binance.com
sudo nping -c "$NUM_PROBES" --tcp -p "$port" "$host"
```

# Results

## apne1-az1 (ap-northeast-1c)

### MD

```text
Max rtt: 1.087ms | Min rtt: 0.647ms | Avg rtt: 0.678ms
Raw packets sent: 100 (4.000KB) | Rcvd: 100 (4.600KB) | Lost: 0 (0.00%)
Nping done: 1 IP address pinged in 99.22 seconds
```

### OE

```text
Max rtt: 0.930ms | Min rtt: 0.528ms | Avg rtt: 0.564ms
Raw packets sent: 100 (4.000KB) | Rcvd: 100 (4.600KB) | Lost: 0 (0.00%)
Nping done: 1 IP address pinged in 99.19 seconds
```

## apne1-az2 (ap-northeast-1d)

### MD

```text
Max rtt: 2.503ms | Min rtt: 1.890ms | Avg rtt: 1.920ms
Raw packets sent: 100 (4.000KB) | Rcvd: 100 (4.600KB) | Lost: 0 (0.00%)
Nping done: 1 IP address pinged in 99.24 seconds
```

### OE

```text
Max rtt: 2.113ms | Min rtt: 1.719ms | Avg rtt: 1.748ms
Raw packets sent: 100 (4.000KB) | Rcvd: 100 (4.600KB) | Lost: 0 (0.00%)
Nping done: 1 IP address pinged in 99.21 seconds
```

## apne1-az4 (ap-northeast-1a)

### MD

```text
Max rtt: 1.009ms | Min rtt: 0.513ms | Avg rtt: 0.552ms
Raw packets sent: 100 (4.000KB) | Rcvd: 100 (4.600KB) | Lost: 0 (0.00%)
Nping done: 1 IP address pinged in 99.21 seconds
```

After optimizations

```text
Max rtt: 0.828ms | Min rtt: 0.433ms | Avg rtt: 0.479ms
Raw packets sent: 100 (4.000KB) | Rcvd: 100 (4.600KB) | Lost: 0 (0.00%)
Nping done: 1 IP address pinged in 99.20 seconds
```

### OE

```text
Max rtt: 1.943ms | Min rtt: 0.348ms | Avg rtt: 0.410ms
Raw packets sent: 100 (4.000KB) | Rcvd: 100 (4.600KB) | Lost: 0 (0.00%)
Nping done: 1 IP address pinged in 99.16 seconds
```

After optimizations

```text
Max rtt: 0.863ms | Min rtt: 0.492ms | Avg rtt: 0.530ms
Raw packets sent: 100 (4.000KB) | Rcvd: 100 (4.600KB) | Lost: 0 (0.00%)
Nping done: 1 IP address pinged in 99.19 seconds
```
