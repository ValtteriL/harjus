# Kirnu

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

Build kirnu and package into a container

```bash
nix-build

# executable then available at ./result-3/bin/kirnu
# container then available at ./result-2
```

### Running

```bash
docker image load -i $(realpath result-2)
docker container run --rm -it <image>

# can also run shell inside container
docker container run --rm -it <image> /bin/sh
```
