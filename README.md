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
