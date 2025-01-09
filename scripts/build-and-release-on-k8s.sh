#!/bin/bash
set -e

# build and run harjus in k8s with dev settings

source .env

nix-build

IMAGE=`docker image load -q < result-2|awk '{print $3}'`

docker tag $IMAGE charlie.koti.kontu:32000/harjus:`git describe --match=NeVeRmAtCh --always --abbrev=12 --dirty`

# push to k8s registry
docker image push $IMAGE

# run in k8s
kubectl run -i -t harjus --image=$IMAGE --restart=Never \
  --env "START_SYMBOLS=$START_SYMBOLS" \
  --env "BINANCE_ED25519_PRIVATE_KEY=$BINANCE_ED25519_PRIVATE_KEY" \
  --env "BINANCE_ED25519_API_KEY=$BINANCE_ED25519_API_KEY"
