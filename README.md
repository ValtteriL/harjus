# Fast-QuickFix

## Setup

- Debian 13
- cpu with SSE4.2 support
- 2 NICS
    - eth0 for control traffic
    - ens19 dedicated for dpdk

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

# TODO
```
