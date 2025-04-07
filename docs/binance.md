# Binance

## API key generation

```bash
openssl genpkey -algorithm ed25519 > $path_to_privkey
openssl pkey -in $path_to_privkey -pubout > $path_to_pubkey

# new for Harjus 2.0.0
openssl genpkey -algorithm ed25519 -out private.pem && openssl pkey -in private.pem -pubout && openssl asn1parse -inform PEM -in private.pem -noout -out seed.bin && base64 seed.bin
```
