# Kirnu

Binance arbitrage bot.

Uses triangular arbitration on Spot trading, and Cash-and-Carry between SPOT and Futures.

## Development

```bash
nix-shell -A devEnv
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

### Build

```bash
nix-build

# executable then available at ./result-2/bin/kirnu
```
