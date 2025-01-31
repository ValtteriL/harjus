# Harjus

Binance arbitrage bot.

Uses triangular arbitration on Spot trading, and Cash-and-Carry between SPOT and Futures.

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

Run static code analysis

```bash
mix dialyzer
```

## Deployment

### Build

Build harjus and package into a container

```bash
nix-build

# executable then available at ./result-3/bin/harjus
# container then available at ./result-2
```

### Running

```bash
IMAGE=`docker image load -q < result-2|awk '{print $3}'`
docker container run --rm -it --env-file .env $IMAGE

# can also run shell inside container
docker container run --rm -it $IMAGE /bin/sh

# push to k8s registry
docker image push $IMAGE

# run in k8s
kubectl run -i -t harjus --image=$IMAGE --restart=Never --env "START_SYMBOLS=BNB" --env "PROD=true"
```

## Setting up Terraform

1. Configure AWS credentials: Ensure that your AWS credentials are configured on your machine. You can do this by setting the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables, or by using the AWS CLI to configure your credentials.

2. Initialize Terraform: Navigate to the `deploy` directory and run the following command to initialize Terraform:

```bash
cd deploy
terraform init
```

## Deploying to QA via Git Tags

1. Create a Git tag: Create a Git tag that matches the pattern `releases/[1-9]+.[0-9]+.[0-9]+`. For example:

```bash
git tag releases/1.0.0
git push origin releases/1.0.0
```

2. GitHub Actions will automatically trigger the `build-and-release.yml` workflow, which will build and deploy the application to the QA environment.

## Pipeline Overview

1. **Quality Pipeline**: Runs all tests on push to any branch.
2. **Build and Release Pipeline**: If the quality pipeline succeeds and the push is to the main branch, a build is made. Additionally the build is deployed to QA if the release tag is used.
