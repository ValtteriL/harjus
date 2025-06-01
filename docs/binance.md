# Binance

## API key generation

```bash
openssl genpkey -algorithm ed25519 > $path_to_privkey
openssl pkey -in $path_to_privkey -pubout > $path_to_pubkey

# new for Harjus 2.0.0
# prints out pubkey (in PEM) and private key seed (raw, base64 encoded)
openssl genpkey -algorithm ed25519 -out private.pem && openssl pkey -in private.pem -pubout && openssl pkey -in private.pem -outform DER | tail -c 32 |base64 && rm private.pem

# Create an API key in Binance with the public key, receive Binance API key
# Remember to set correct permissions

# Record private key seed, Binance API key to Ansible vault
# paste in the secret and press Ctrl-d twice. Do not press enter!
ansible-vault encrypt_string --vault-password-file deploy/playbooks/.ansible_vault_password
# Paste the encrypted string to values file in deploy/playbooks/group_vars/harjus_instance/
```
