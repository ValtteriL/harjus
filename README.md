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
    <a href="https://shufflingbytes.com/posts/binance-triangular-arbitrage/"><strong>Read the writeup »</strong></a>
  </p>
</div>

## Demo

Exploiting triangular arbitrage opportunities in Binance testnet
[![asciicast](https://asciinema.org/a/730934.svg)](https://asciinema.org/a/730934)

## Requirements

- VirtualBox
- Vagrant
- VSCode with Remote - SSH extension

## Development

Development is done inside a Vagrant VM accessed via VSCode Remote SSH. The VM provides a consistent development environment with all necessary dependencies pre-installed.

```bash
vagrant up
```

By default, the VM is allocated 50% of your host's CPU and RAM. You can override this with environment variables:

```bash
# Allocate 8 CPUs and 16 GB RAM
VM_CPUS=8 VM_RAM_GB=16 vagrant up
```

### VM Resource Configuration

| Environment Variable | Description                     | Default          |
| -------------------- | ------------------------------- | ---------------- |
| `VM_CPUS`            | Number of CPU cores to allocate | 50% of host CPUs |
| `VM_RAM_GB`          | Amount of RAM in GB to allocate | 50% of host RAM  |

## Test

Run unit tests

```bash
just test
```

### Automatic tests

The unit tests are run by CI/CD on push to any branch.

## Build

Build harjus

```bash
just build
```

## Release

1. Create a Git tag: Create a Git tag that matches the pattern `releases/[1-9]+.[0-9]+.[0-9]+`. For example:

```bash
git tag releases/1.0.0
git push origin releases/1.0.0
```

2. Trigger the build for the tag manually through Jenkins.

## Deployment

Deployment is done manually from local shell.

### Prerequisite: Create Terraform backend in S3

```bash
terraform -chdir=deploy/backend init
terraform -chdir=deploy/backend apply
```

### Prerequisite: Provision host

```bash
terraform -chdir=deploy init
terraform -chdir=deploy apply

(cd deploy/playbooks && uv run ansible-playbook setup.yml)
```

### Deploy

```bash
# QA (testnet)
(cd deploy/playbooks && uv run ansible-playbook deploy.yml -e "env=qa") # defaults to 'latest' version
(cd deploy/playbooks && uv run ansible-playbook deploy.yml -e "env=qa" -e "version=your-semver-or-git-hash-or-latest")

# Prod
(cd deploy/playbooks && uv run ansible-playbook deploy.yml -e "env=prod")
```

## Debugging

### Access prod server

```bash
ssh -o StrictHostKeyChecking=no -i deploy/harjus-ec2-key.pem ubuntu@$(terraform -chdir=deploy output instance_ip|sed 's/"//g')
```

### Inspect service

```bash
sudo systemctl status harjus
# or
sudo journalctl -au harjus.service
```

### List build artifacts

```bash
aws s3 ls $(terraform -chdir=deploy output artifact_bucket_name)
```

### check deployed version

```bash
# on prod server
cat $(readlink $(which harjus) | sed 's/\/bin\/harjus//g')/version.txt
```
