# Flashfix

## Setup

- Debian 13
- cpu with SSE4.2 support
- 2 NICS
  - eth0 for control traffic
  - ens19 dedicated for dpdk (of type vmxnet3)

```bash
# setup dependencies
sudo apt install just
source <(just --completions bash) # may want to put into bashrc
just provision
```

## Running

```bash
# prepare kernel bypass
just initialize
```

### Echo server

```bash
# launch echo server
just echo

# connect to it to play around
nc -v 172.16.1.22 80

# stop echo
just stop-echo
```

## Misc

This product includes software developed by quickfixengine.org (<http://www.quickfixengine.org/>).
