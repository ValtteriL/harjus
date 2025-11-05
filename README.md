# Fast-QuickFix

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

# launch helloworld http server
just helloworld

# get served page
curl -v http://172.16.1.22

# stop helloworld
just stop-helloworld
```
