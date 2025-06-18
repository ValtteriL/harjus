# Harjus

Binance arbitrage bot.

Captures triangular arbitrage opportunities on Spot trading.

![build workflow](https://github.com/ValtteriL/harjus/actions/workflows/build.yml/badge.svg)

## Development

```bash
nix-shell -A devEnv
```

### Test

Run unit tests

```bash
cmake -B build -G Ninja
ninja -C build -j$(nproc)
ctest --test-dir build/
```

### Automatic tests

The unit tests are run by CI/CD on push to any branch.

## Build

Build harjus

```bash
nix-build -A harjus

# harjus executable available at ./result/bin/harjus
```

### Automatic builds

Harjus packages are build automatically by CI/CD and pushed to S3. If the quality stage succeeds and the push is to the `main` branch, a build is made and its pushed with git hash tag and the `latest` tag.

When a special release tag (releases/$semver) is pushed to any commit, if the quality stage succeeds, CI/CD builds a package with the $semver as the version string.

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

(cd deploy/playbooks && ansible-playbook setup.yml)
```

### Deploy

```bash
# QA (testnet)
(cd deploy/playbooks && ansible-playbook deploy.yml -e "env=qa") # defaults to 'latest' version
(cd deploy/playbooks && ansible-playbook deploy.yml -e "env=qa" -e "version=your-semver-or-git-hash-or-latest")

# Prod
(cd deploy/playbooks && ansible-playbook deploy.yml -e "env=prod")
```

## Debugging

### Access prod server

```bash
ssh -o StrictHostKeyChecking=no -i deploy/harjus-ec2-key.pem ec2-user@$(terraform -chdir=deploy output instance_ip|sed 's/"//g')
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
