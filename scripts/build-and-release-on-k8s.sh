#!/bin/bash
set -e

# build and run harjus in k8s with dev settings

source .env

nix-build

IMAGE=`docker image load -q < result-2|awk '{print $3}'`

# push to k8s registry
docker image push $IMAGE

# run in k8s
kubectl run -i -t harjus --image=$IMAGE --restart=Never \
  --env "START_SYMBOLS=BNB" \
  --env "BINANCE_ED25519_PUBLIC_KEY=$BINANCE_ED25519_PUBLIC_KEY" \
  --env "BINANCE_ED25519_PRIVATE_KEY=$BINANCE_ED25519_PRIVATE_KEY" \
  --env "BINANCE_API_KEY=$BINANCE_API_KEY"
