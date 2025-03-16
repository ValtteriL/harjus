# Binance

## API key generation

```bash
openssl genpkey -algorithm ed25519 > $path_to_privkey
openssl pkey -in $path_to_privkey -pubout > $path_to_pubkey
```
