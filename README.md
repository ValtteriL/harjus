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

Build harjus and package into a container

```bash
nix-build

# container then available at ./result-2
# harjus executable available at ./result-3/bin/harjus

# build individual packages (built result available then at `result`):
nix-build -A harjusBuild
```

### Automatic builds

Container images are build automatically by CI/CD and pushed to registry. If the quality stage succeeds and the push is to the `main` branch, a build is made and its pushed to registry with git hash tag and the `latest` tag.

When a special release tag (releases/$semver) is pushed to any commit, if the quality stage succeeds, CI/CD builds the container image and pushes it to the registry with the git hash tag and the $semver tag.

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
(cd deploy/playbooks && ansible-playbook deploy.yml -e "env=qa") # defaults to latest tag
(cd deploy/playbooks && ansible-playbook deploy.yml -e "env=qa" -e "image_tag=your-git-hash-for-qa")

# Prod
(cd deploy/playbooks && ansible-playbook deploy.yml -e "env=prod")
```

## Debugging

### Access container runner

```bash
ssh -o StrictHostKeyChecking=no -i deploy/harjus-ec2-key.pem ec2-user@$(terraform -chdir=deploy output instance_ip|sed 's/"//g')
```

### Inspect service

```bash
sudo systemctl status harjus
# or
sudo journalctl -au harjus.service
```

### Inspect containers running on runner

```bash
docker ps

# top processes in container
docker top <id>

# get cpu, memory usage for containers
docker stats

# get detailed configuration and status for container
docker inspect <id>

# get envs of container
docker inspect -f '{{range $index, $value := .Config.Env}}{{$value}} {{end}}' <id>
```
