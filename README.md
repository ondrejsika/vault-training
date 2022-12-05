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

## Dynamic Secrets

## Database (Postgres)

Run Postgres

```
make postgres-up
```

Create role `ro` (read only for all tables)

```
make postgres-create-ro
```

Enable `database` secret engine

```
vault secrets enable database
```

Configure Postgress connection

```
vault write database/config/postgresql \
  plugin_name=postgresql-database-plugin \
  connection_url="postgresql://{{username}}:{{password}}@127.0.0.1:5432/postgres?sslmode=disable" \
  allowed_roles=readonly \
  username="postgres" \
  password="pg"
```

Create read-only role

```
vault write database/roles/readonly \
    db_name=postgresql \
    creation_statements=@examples/postgres/readonly.sql \
    default_ttl=2m \
    max_ttl=24h
```

Read credentials

```
vault read database/creds/readonly
```

Validate

```
POSTGRES_USER=...
POSTGRES_PASSWORD=...
```

```
slu postgres ping -H 127.0.0.1 -P 5432 -u $POSTGRES_USER -p $POSTGRES_PASSWORD -n postgres
```

Wait one minute & check again:

```
sleep 60
slu postgres ping -H 127.0.0.1 -P 5432 -u $POSTGRES_USER -p $POSTGRES_PASSWORD -n postgres
```

### AWS

Enable AWS secret engine

```
vault secrets enable aws
```

Prepare AWS keys

```
export AWS_ACCESS_KEY=...
export AWS_SECRET_KEY=...
```

Configure the AWS provider

```
vault write aws/config/root \
  access_key=$AWS_ACCESS_KEY \
  secret_key=$AWS_SECRET_KEY \
  region=eu-central-1
```

Create s3 role

```
vault write aws/roles/s3 \
  credential_type=iam_user \
  policy_document=@examples/aws/s3_policy.json
```

Get credentials

```
vault read aws/creds/s3
```

# Production Vault on Kubernetes

Docs:

- [Highly Available Vault Cluster with Integrated Storage (Raft)](https://www.vaultproject.io/docs/platform/k8s/helm/examples/ha-with-raft)

Install production Vault

```
make prod-server
```

Init

```
kubectl exec -ti vault-0 -- vault operator init
```

Unseal

```
kubectl exec -ti vault-0 -- vault operator unseal
```

Add nodes to cluster

```
kubectl exec -ti vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
```

and unseal

```
kubectl exec -ti vault-1 -- vault operator unseal
```

Do it for the 3rd node:

```
kubectl exec -ti vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
```

```
kubectl exec -ti vault-2 -- vault operator unseal
```

Done.

Set environment:

```
export VAULT_ADDR=...
export VAULT_TOKEN=...
```

Check status:

```
vault status
```

List raft peers:

```
vault operator raft list-peers
```

## Backup & Restore

## Backup

```
vault operator raft snapshot save backup.snap
```

## Restore

Create new cluster, unseal & login to it.

```
vault operator raft snapshot restore -force backup.snap
```

## Backup using Tergum

- Tergum - Backup tool - https://github.com/sikalabs/tergum
- Blog post about backup - https://ondrej-sika.cz/blog/tergum-v0.30.0

Copy example config & edit token

```
make tergum-copy-config
vim tergum.yml
```

Run backup

```
tergum backup --config tergum.yml
```

## Kubernetes Injector Example

Enable injector

```
make k8s-prod-server-with-injector
```

Create kv engine for Kubernetes demo

```
vault secrets enable -path=secret-k8s kv-v2
```

Put secret

```
vault kv put secret-k8s/database/config username="foo" password="bar"
```

Validate secret

```
vault kv get secret-k8s/database/config
```

Enable Kubernetes auth backend

```
vault auth enable kubernetes
```

Connect the Vault pod

```
kubectl exec -ti vault-0 -n vault -- sh
```

Connect Kubernets

```
vault write auth/kubernetes/config \
  kubernetes_host="https://$KUBERNETES_PORT_443_TCP_ADDR:443" \
  token_reviewer_jwt="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  issuer="https://kubernetes.default.svc.cluster.local"
```

Create policy for our app

```
vault policy write hello ./examples/k8s-injector/policy.hcl
```

Create role for our app

```
vault write auth/kubernetes/role/hello \
  bound_service_account_names=hello \
  bound_service_account_namespaces=default \
  policies=hello \
  ttl=24h
```

Install App

```
kubectl apply -f ./examples/k8s-injector
```

Open port forward and check the app

```
kubectl port-forward svc/hello 8000:80
```

See:

- <http://127.0.0.1:8000>
- <http://127.0.0.1:8000/vault/secrets/database-config.txt>

## HashiCorp Video about Kubernetes Integration

<https://www.youtube.com/watch?v=xUuJhgDbUJQ&t=26s&ab_channel=HashiCorp>

## Thank you! & Questions?

That's it. Do you have any questions? **Let's go for a beer!**

### Ondrej Sika

- email: <ondrej@sika.io>
- web: <https://sika.io>
- twitter: [@ondrejsika](https://twitter.com/ondrejsika)
- linkedin: [/in/ondrejsika/](https://linkedin.com/in/ondrejsika/)
- Newsletter, Slack, Facebook & Linkedin Groups: <https://join.sika.io>

_Do you like the course? Write me recommendation on Twitter (with handle `@ondrejsika`) and LinkedIn (add me [/in/ondrejsika](https://www.linkedin.com/in/ondrejsika/) and I'll send you request for recommendation). **Thanks**._

Wanna to go for a beer or do some work together? Just [book me](https://book-me.sika.io) :)
