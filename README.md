[Ondrej Sika (sika.io)](https://sika.io) | <ondrej@sika.io>

# Vault Training

    2020 Ondrej Sika <ondrej@ondrejsika.com>
    https://github.com/ondrejsika/vault-training

## Live Chat

For sharing links & "secrets".

- Campfire - https://sika.link/join-campfire
- Slack - https://sikapublic.slack.com/
- Microsoft Teams
- https://sika.link/chat (tlk.io)

## Run Vault Dev Server

### Local Binary

Run

```
make local-dev-server
```

Stop: using Ctrl+C

See: <http://127.0.0.1:8200>

Test it

```
VAULT_ADDR=http://127.0.0.1:8200 VAULT_TOKEN=root vault status
```

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
vault kv destroy -versions 1 secret/first
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
kubectl exec -ti -n vault vault-0 -- vault operator init
```

Unseal

```
kubectl exec -ti -n vault vault-0 -- vault operator unseal
```

Add nodes to cluster

```
kubectl exec -ti -n vault vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
```

and unseal

```
kubectl exec -ti -n vault vault-1 -- vault operator unseal
```

Do it for the 3rd node:

```
kubectl exec -ti -n vault vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
```

```
kubectl exec -ti -n vault vault-2 -- vault operator unseal
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

## Vault Secrets Operator

- https://github.com/ondrejsika/vault-secrets-operator-example
- https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator

### Install Vault Secrets Operator

Install operator

```
helm upgrade --install \
  vault-secrets-operator \
  --repo https://helm.releases.hashicorp.com \
  vault-secrets-operator \
  --namespace vault-secrets-operator-system \
  --create-namespace \
  --values examples/vault_secrets_operator/vault_secrets_operator.values.yml
```

Check if the operator is running

```
kubectl get po -n vault-secrets-operator-system
```

## Enable Kubernetes Auth

```
vault auth enable kubernetes
```

## Configure Kubernetes Auth

```
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc.cluster.local:443"
```

## Create Secret Engine

```
vault secrets enable -path=test kv-v2
```

## Add Secret

```
vault kv put test/example username=foo password=bar
```

## Create Policy

```
vault policy write test-read - <<EOF
path "test/*" {
  capabilities = ["read"]
}
EOF
```

```
vault write auth/kubernetes/role/test-read \
  bound_service_account_names=default \
  bound_service_account_namespaces=default \
  policies=test-read \
  audience=vault \
  ttl=24h
```

## Create Vault Auth

```
kubectl apply -f examples/vault_secrets_operator/vaultauth.yml
```

## Create Vault Secret

```
kubectl apply -f examples/vault_secrets_operator/vaultstaticsecret.yml
```

## Check Secret

```
kubectl get secret example -o jsonpath='{.data.username}' | base64 --decode && echo
kubectl get secret example -o jsonpath='{.data.password}' | base64 --decode && echo
```

## Vault OIDC Auth using Keycloak

```
vault policy write manager examples/oidc/manager.hcl
```

```
vault policy write reader examples/oidc/reader.hcl
```

```
vault policy list
```

Enable the Keycloak authentication method in Vault by running the following command:

```
vault auth enable oidc
```

Configure the Keycloak provider by specifying the issuer URL, client ID, client secret, and any other necessary parameters. For example:

```
vault write auth/oidc/config \
  oidc_discovery_url="https://sso.sikalabs.com/realms/sikademo" \
  oidc_client_id="default" \
  oidc_client_secret="default" \
  oidc_scope="openid profile email roles" \
  default_role="default"
```

```
vault write auth/oidc/role/manager \
  bound_audiences="default" \
  allowed_redirect_uris="http://localhost:8200/ui/vault/auth/oidc/oidc/callback" \
  allowed_redirect_uris="http://localhost:8250/oidc/callback" \
  user_claim="email" \
  token_policies="manager" \
  groups_claim="groups" \
  allowed_groups="vault-manager"
```

```
vault write auth/oidc/role/default \
  bound_audiences="default" \
  allowed_redirect_uris="http://localhost:8200/ui/vault/auth/oidc/oidc/callback" \
  allowed_redirect_uris="http://localhost:8250/oidc/callback" \
  user_claim="email" \
  token_policies="reader"
```

```
vault login -method=oidc
```

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
