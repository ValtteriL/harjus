# Harjus

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/ValtteriL/harjus">
    <img src="images/harjus-logo.png" alt="Logo" width="300" height="300">
  </a>

  <h3 align="center">Harjus</h3>

  <p align="center">
    Binance Spot Arbitrage Bot
    <br />
    <a href="https://shufflingbytes.com/posts/binance-triangular-arbitrage/"><strong>Read the writeup (releases 1-3) »</strong></a>
  </p>
</div>

Ultra low latency Binance Spot Market [triangular arbitrage](https://en.wikipedia.org/wiki/Triangular_arbitrage) trading bot utilizing kernel bypass.

## Demo

Running v4.0.0 in Binance testnet
[![asciicast](https://asciinema.org/a/789065.svg)](https://asciinema.org/a/789065)

## Development

Development is done inside a Vagrant VM [accessed via VSCode Remote SSH](https://medium.com/@lizrice/ssh-to-vagrant-from-vscode-5b2c5996bc0e). The VM provides a consistent development environment with all necessary dependencies pre-installed, and an extra network card to dedicate to Harjus.

```bash
vagrant up
```

By default, the VM is allocated 50% of your host's CPU and RAM. You can override this with environment variables:

```bash
# Allocate 8 CPUs and 16 GB RAM
VM_CPUS=8 VM_RAM_GB=16 vagrant up
```

### Requirements

- VirtualBox
- Vagrant
- VSCode with Remote - SSH extension

### List available commands

```bash
just
```

### Build

```bash
# build F-Stack release (only needs to be ran once)
just fstack::release

# debug build
just build

# release build
just build-release
```

### Test

```bash
just test
```

### Run

```bash
# create .env following the sample
# this is the main configuration
cp .env.sample .env
vim .env

# debug build
just run

# release build
just run-release
```

## Deployment

Harjus is deployed to the availability zone closest to Binance FIX API Marked Data endpoint in AWS. This ensures the bot has the best conditions to learn about arbitrage opportunities before other participants.

### Requirements

- All development requirements
- AWS CLI
- Terraform
- Ansible
- python3-botocore
- python3-boto3

### List available deployment commands

```bash
just deploy
```

### Preparation

The optimal availability zone differs for each user. Use the latency measurement utility to find out yours. See [detailed instructions](./docs/choose-optimal-az.md).

```bash
# Measure latency to find optimal availability zone
just deploy::measure-latency

# create .env following the sample
# this is the main configuration
cp .env.sample .env
vim .env
```

### Deploying

```bash
# Build and package release
just build-release <architecture>
just package

# Setup Terraform backend (run once)
just deploy::setup-backend

# Setup server in the optimal availability zone (use AZ from latency measurement)
just deploy::setup-server <aws_availability_zone>
# for example: just deploy::setup-server ap-northeast-1a

# Deploy (requires release package path)
just deploy::deploy <package_path>
# for example: just deploy::deploy dist/harjus.tar.gz

# Connect to server via SSH
just deploy::connect-server

# Cleanup server
just server-cleanup

# Cleanup all resources
just deploy::cleanup
```
