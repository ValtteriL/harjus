# Harjus

Binance arbitrage bot.

Captures triangular arbitrage opportunities on Spot trading.

![build workflow](https://github.com/ValtteriL/harjus/actions/workflows/build.yml/badge.svg)

## Development

```bash
nix-shell -A devEnv

# start shell with or without the starting application
iex -S mix
iex -S mix run --no-start
```

### Test

Run unit tests

```bash
mix test
```

Run all tests

```bash
mix test --include integration:true
```

Run static code analysis

```bash
mix dialyzer
```

Run full quality checkup (all tests, formatter, credo, dialyzer)

```bash
# this will format the code
mix quality

# this will fail on any issues
mix quality.ci
```

### Automatic tests

The quality.ci is run by CI/CD **Quality Pipeline** on push.

## Build

Build harjus and package into a container

```bash
nix-build

# executable then available at ./result-3/bin/harjus
# container then available at ./result-2
```

### Automatic builds

Container images are build automatically by CI/CD **Build Pipeline** and pushed to registry. If the quality pipeline succeeds and the push is to the main branch, a build is made and its pushed to registry with git hash tag.
The image is additionally pushed with release version tag if release tag pushed in git.

Pushing with release tag:

1. Create a Git tag: Create a Git tag that matches the pattern `releases/[1-9]+.[0-9]+.[0-9]+`. For example:

```bash
git tag releases/1.0.0
git push origin releases/1.0.0
```

## Deployment

Deployment is done manually from local shell.

### Prerequisite: Create Terraform backend in S3

```bash
terraform -chdir=deploy/backend init
terraform -chdir=deploy/backend apply
```

Set the output from into s3 backend in deploy

### Deploy

```bash
terraform -chdir=deploy init
terraform -chdir=deploy apply -var-file="$env.tfvars" -var "image_tag=$image_tag_to_deploy"
```

## Debugging

### Access container runner

```bash
ssh -o StrictHostKeyChecking=no -i deploy/harjus-ec2-key.pem ec2-user@$(terraform -chdir=deploy output ecs_instance_ip|sed 's/"//g')
```
