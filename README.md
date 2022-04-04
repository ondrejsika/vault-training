[Ondrej Sika (sika.io)](https://sika.io) | <ondrej@sika.io>

# Vault Training

    2020 Ondrej Sika <ondrej@ondrejsika.com>
    https://github.com/ondrejsika/vault-training


## Run Vault Dev Server

### Local Binary

Run

```
make local-dev-server
```

Stop: using Ctrl+C

See: <http://127.0.0.1:8200>

### From Docker

Run

```
make docker-dev-server-up
```

Stop

```
make docker-dev-server-down
```

Logs

```
make docker-dev-server-logs
```

### `~/.vault-token`

If you run Vault locally, your token will be automaticaly save to file `~/.vault-token`.

If you run Vault from Docker, you have to create that file manually:

```bash
echo root > ~/.vault-token
```

### Test CLI / `vault status`

You need to set `http://127.0.0.1:8200` to environment variable `VAULT_ADDR`.

```bash
export VAULT_ADDR='http://127.0.0.1:8200'
```

Now, try:

```bash
vault status
```

![](./images/vault-status.png)

If you run Vault in Docker and dont have Vault locally, you can connect to shell using

```
make docker-dev-server-shell
```

And just run `vault status`. Everything is configured.

## Static Secrets

Available commands for `vault kv <command> ...`

- `delete` - Delete versions of secrets stored in K/V
- `destroy` - Permanently remove one or more versions of secrets
- `enable-versioning` - Turns on versioning for an existing K/V v1 store
- `get` - Retrieve data
- `list` - List data or secrets
- `metadata` -Interact with Vault's Key-Value storage
- `patch` -Update secrets without overwriting existing secrets
- `put` - Sets or update secrets (this replaces existing secrets)
- `rollback` - Rolls back to a previous version of secrets
- `undelete` - Restore the deleted version of secrets

### List Static Secrets

```
vault kv list secret/
```

### Put Static Secret

```
vault kv put secret/first hello=world foo=bar
```

and list again

```
vault kv list secret/
```

### Get Static Secret

```
vault kv get secret/first
```

### Update Static Secret

```
vault kv patch secret/first ahoj=svete
```

```
vault kv get secret/first
```

```
vault kv patch secret/first foo=baz
```

```
vault kv get secret/first
```

```
vault kv put secret/first ahoj=svete
```

```
vault kv get secret/first
```

### Delete Static Secret

```
vault kv delete secret/first
```

```
vault kv get secret/first
```

### Static Secrets Versions

```
vault kv get -version 1 secret/first
```

```
vault kv get -version 2 secret/first
vault kv get -version 3 secret/first
```

### Destroy Static Secret

```
vault kv destroy -version 1 secret/first
```

```
vault kv get -version 1 secret/first
```

```
vault kv get -version 2 secret/first
```

### Destroy All Versions of Static Secret

```
vault delete secret/metadata/first
```

```
vault kv list secret/
```
