# Binance

## API key generation

```bash
openssl genpkey -algorithm ed25519 > $path_to_privkey
openssl pkey -in $path_to_privkey -pubout > $path_to_pubkey

# new for Harjus 2.0.0
# prints out pubkey (in PEM) and private key seed (raw, base64 encoded)
openssl genpkey -algorithm ed25519 -out private.pem && openssl pkey -in private.pem -pubout && openssl pkey -in private.pem -outform DER | tail -c 32 |base64 && rm private.pem
```
