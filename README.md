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
