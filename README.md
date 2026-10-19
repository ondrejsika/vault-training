[Ondrej Sika (sika.io)](https://sika.io) | <ondrej@sika.io>

# Vault Training

## Live Chat

For sharing links & "secrets".

- Campfire - https://sika.link/join-campfire
- Slack - https://sikapublic.slack.com/
- Microsoft Teams
- https://sika.link/chat (tlk.io)

## Vault Community vs Enterprise

https://developer.hashicorp.com/vault/tutorials/get-started/available-editions

We will use **Vault Community** (open source).

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

### From Docker Compose

Example is [examples/vault_in_docker](./examples/vault_in_docker)

Run

```
make -C ./examples/vault_in_docker up
```

Stop

```
make -C ./examples/vault_in_docker down
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

If you run Vault locally, your token will be automatically saved to file `~/.vault-token`.

If you run Vault from Docker, you have to create that file manually:

```bash
echo root > ~/.vault-token
```

### Test CLI / `vault status`

You need to set the environment variable `VAULT_ADDR` to `http://127.0.0.1:8200`.

```bash
export VAULT_ADDR='http://127.0.0.1:8200'
```

Now, try:

```bash
vault status
```

![](./images/vault-status.png)

If you run Vault in Docker and don't have Vault installed locally, you can connect to the container shell using

```
make docker-dev-server-shell
```

And just run `vault status`. Everything is configured.

## How Vault Works

Before we store any secret, let's look at the main parts of Vault. You can see most of them in the `vault status` output above.

### Storage Backend

Vault does not store data itself; it uses a **storage backend**. Everything Vault writes to the storage is **encrypted**, so the storage never sees any secret in plain text.

- `inmem` - in memory, used by the dev server (`Storage Type: inmem`), everything is lost on restart
- `raft` - Integrated Storage, built into Vault, replicated between Vault nodes, recommended for production (we will use it on Kubernetes)
- `file`, `consul`, `postgresql`, ...

Docs: https://developer.hashicorp.com/vault/docs/configuration/storage

### Seal / Unseal

The data in the storage is encrypted by the **encryption key**. The encryption key is encrypted by the **root key** (also called the master key). Vault keeps the root key only in memory.

When Vault starts, it is **sealed**. It knows where the data is, but it can't decrypt it. It can't do anything except unseal.

**Unsealing** means rebuilding the root key in memory. By default (`Seal Type: shamir`), the root key is split into **key shares** using [Shamir's Secret Sharing](https://en.wikipedia.org/wiki/Shamir%27s_secret_sharing). `vault operator init` creates 5 shares, and any 3 of them (the threshold) can rebuild the root key. You can give the shares to different people, so no one can unseal Vault alone.

After a restart (or a crash, or a new pod), Vault is sealed again and **somebody has to unseal it**. That's why production setups use [auto-unseal](#auto-unseal).

The dev server is initialized and unsealed automatically with only 1 key share. You can find the unseal key in the server output (`Unseal Key: ...`). If you run Vault in Docker:

```
docker logs vault-dev 2>&1 | grep 'Unseal Key'
```

Seal Vault (for example, in an emergency)

```
vault operator seal
```

```
vault status
```

Try to do something

```
vault secrets list
```

Unseal Vault using the unseal key

```
vault operator unseal
```

```
vault status
```

### Secrets Engines

Secrets engines store, generate, or encrypt data. Each one is mounted at a path; for example, the dev server has KV v2 at `secret/`.

```
vault secrets list
```

### Auth Methods

Auth methods check who you are (a username and password, an OIDC login, a Kubernetes service account, ...). If the login succeeds, they give you a **token**.

```
vault auth list
```

### Tokens

**Everything in Vault is done with a token.** Every auth method just turns your identity into a token. The token has **policies** attached, which say what the token can do.

The `root` token can do everything. Use it only for the initial setup.

```
vault token lookup
```

### Leases & TTLs

Tokens and dynamic secrets have a **lease** with a **TTL** (time to live). When the TTL expires, Vault revokes them: it deletes the token or, for example, drops the database user. You can **renew** a lease (up to `max_ttl`) or **revoke** it early.

Static KV secrets don't have leases.

### Paths

Everything in Vault is a path; the CLI just calls the HTTP API.

- `secret/...` - KV secrets engine
- `database/...` - Database secrets engine
- `auth/userpass/...` - userpass auth method
- `sys/...` - system backend (configuration of Vault itself)

See the API call behind any CLI command:

```
vault secrets list -output-curl-string
```

## Static Secrets

Available commands for `vault kv <command> ...`

- `delete` - Delete versions of secrets stored in K/V
- `destroy` - Permanently remove one or more versions of secrets
- `enable-versioning` - Turns on versioning for an existing K/V v1 store
- `get` - Retrieve data
- `list` - List data or secrets
- `metadata` - Interact with Vault's Key-Value storage
- `patch` - Update secrets without overwriting existing secrets
- `put` - Set or update secrets (this replaces existing secrets)
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

## Policies

Docs: https://developer.hashicorp.com/vault/docs/concepts/policies

Policies say **what a token can do on which path**. Vault denies everything by default. A token can do only what its policies allow.

Capabilities:

- `create` - create new data (`POST`/`PUT` to a path that doesn't exist)
- `read` - read data (`GET`)
- `update` - change existing data (`POST`/`PUT`)
- `patch` - patch data (`PATCH`)
- `delete` - delete data (`DELETE`)
- `list` - list keys (`LIST`)
- `sudo` - access root-protected paths
- `deny` - deny access, always wins

Built-in policies:

- `root` - can do everything
- `default` - attached to every token, lets the token look up and renew itself

```
vault policy list
```

```
vault policy read default
```

### KV v2 Paths in Policies

This confuses a lot of people. **For KV v2, the path in the CLI is not the path in the API.**

When you run `vault kv get secret/myapp/config`, the CLI calls `secret/data/myapp/config`. You can see it in the output (`Secret Path: secret/data/myapp/config`).

| CLI command | Path in policy | Capability |
| --- | --- | --- |
| `vault kv get secret/myapp/config` | `secret/data/myapp/config` | `read` |
| `vault kv put secret/myapp/config ...` | `secret/data/myapp/config` | `create`, `update` |
| `vault kv patch secret/myapp/config ...` | `secret/data/myapp/config` | `patch` |
| `vault kv list secret/myapp` | `secret/metadata/myapp` | `list` |
| `vault kv metadata get secret/myapp/config` | `secret/metadata/myapp/config` | `read` |
| `vault kv delete secret/myapp/config` | `secret/data/myapp/config` | `delete` |
| `vault kv undelete -versions=1 secret/myapp/config` | `secret/undelete/myapp/config` | `update` |
| `vault kv destroy -versions=1 secret/myapp/config` | `secret/destroy/myapp/config` | `update` |
| `vault kv metadata delete secret/myapp/config` | `secret/metadata/myapp/config` | `delete` |

So a policy with `path "secret/myapp/*"` **matches nothing** in KV v2. You have to use `secret/data/myapp/*` and `secret/metadata/myapp/*`.

A policy with `path "secret/*"` matches all of them (`secret/data/...`, `secret/metadata/...`, ...). That's why it works, but it gives access to the whole mount.

### Write Policy

Create a test secret

```
vault kv put secret/myapp/config db_password=s3cret
```

Write a **wrong** policy (it uses a KV v1 style path)

```
vault policy write wrong - <<EOF
path "secret/myapp/*" {
  capabilities = ["read"]
}
EOF
```

Create a token with this policy and try to read the secret

```
WRONG_TOKEN=$(vault token create -policy=wrong -field=token)
```

```
VAULT_TOKEN=$WRONG_TOKEN vault kv get secret/myapp/config
```

Permission denied.

Now write the correct policy, see [examples/policies/myapp_read.hcl](./examples/policies/myapp_read.hcl)

```
vault policy write myapp-read examples/policies/myapp_read.hcl
```

```
vault policy read myapp-read
```

```
MYAPP_TOKEN=$(vault token create -policy=myapp-read -field=token)
```

```
VAULT_TOKEN=$MYAPP_TOKEN vault kv get secret/myapp/config
```

```
VAULT_TOKEN=$MYAPP_TOKEN vault kv list secret/myapp
```

Try to write (it is a read-only policy)

```
VAULT_TOKEN=$MYAPP_TOKEN vault kv put secret/myapp/config db_password=hacked
```

Permission denied.

Check the token's capabilities on a path

```
vault token capabilities $MYAPP_TOKEN secret/data/myapp/config
vault token capabilities $MYAPP_TOKEN secret/data/other/config
```

A policy for full management of `secret/myapp/*` is in [examples/policies/myapp_write.hcl](./examples/policies/myapp_write.hcl).

```
vault policy write myapp-write examples/policies/myapp_write.hcl
```

Cleanup

```
vault policy delete wrong
```

## Auth Methods

Docs: https://developer.hashicorp.com/vault/docs/auth

There are auth methods for **humans** (userpass, OIDC, LDAP, GitHub, ...) and for **machines** (AppRole, Kubernetes, AWS, JWT, TLS certificates, ...).

```
vault auth list
```

### Userpass

The simplest auth method for humans: a username and a password stored in Vault. It is good for demos and small setups. In a company, use OIDC (see [Vault OIDC Auth using Keycloak](#vault-oidc-auth-using-keycloak)) or LDAP instead.

Enable userpass

```
vault auth enable userpass
```

Create a user

```
vault write auth/userpass/users/alice \
  password=alice \
  token_policies=myapp-read \
  token_ttl=1h \
  token_max_ttl=8h
```

```
vault list auth/userpass/users
```

Log in as alice. The `-no-store` flag keeps your root token in `~/.vault-token`.

```
vault login -method=userpass -no-store username=alice
```

Use the token from the output

```
VAULT_TOKEN=... vault kv get secret/myapp/config
```

```
VAULT_TOKEN=... vault token lookup
```

### AppRole

Docs: https://developer.hashicorp.com/vault/docs/auth/approle

AppRole is the main way **applications** (CI jobs, servers, scripts) log in to Vault when they don't run on a platform with its own auth method (like Kubernetes or AWS).

The application needs two values:

- **Role ID** - like a username, not secret, you can put it in the application config
- **Secret ID** - like a password, secret, short-lived, delivered to the application separately (for example by CI or by a deployment tool)

Enable AppRole

```
vault auth enable approle
```

Create a role

```
vault write auth/approle/role/myapp \
  token_policies=myapp-read \
  token_ttl=1h \
  token_max_ttl=4h \
  secret_id_ttl=24h \
  secret_id_num_uses=10
```

Get the Role ID

```
vault read auth/approle/role/myapp/role-id
```

```
ROLE_ID=$(vault read -field=role_id auth/approle/role/myapp/role-id)
```

Generate a Secret ID

```
vault write -f auth/approle/role/myapp/secret-id
```

```
SECRET_ID=$(vault write -f -field=secret_id auth/approle/role/myapp/secret-id)
```

Log in as the application

```
vault write auth/approle/login role_id=$ROLE_ID secret_id=$SECRET_ID
```

```
APP_TOKEN=$(vault write -field=token auth/approle/login role_id=$ROLE_ID secret_id=$SECRET_ID)
```

Read the secret as the application

```
VAULT_TOKEN=$APP_TOKEN vault kv get -field=db_password secret/myapp/config
```

The same login using the HTTP API (what your application does)

```
curl -s -X POST $VAULT_ADDR/v1/auth/approle/login \
  -d "{\"role_id\":\"$ROLE_ID\",\"secret_id\":\"$SECRET_ID\"}" | jq .auth
```

List Secret ID accessors

```
vault list auth/approle/role/myapp/secret-id
```

## Terminal UI for Vault

- vaul7y - https://github.com/dkyanakiev/vaul7y
- v7y (SikaLabs fork of vaul7y) - https://github.com/sikalabsx/v7y

## Create .env File From Vault Secret

Create test secret

```
vault kv put secret/example/prod/env MY_HELLO=world MY_FOO=bar
```

Create `.env`

```
slu vault create-env-file -a http://127.0.0.1:8200 -t root -p example/prod/env
```

Test `.env`

```
cat .env
```

Cleanup

```
vault delete secret/metadata/example/prod/env
```

## Dynamic Secrets

### Database (Postgres)

Run Postgres

```
make postgres-up
```

Create role `ro` (read only for all tables)

```
make postgres-create-ro
```

Enable `database` secrets engine

```
vault secrets enable database
```

Configure Postgres connection

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

Wait two minutes (until the `default_ttl` expires) & check again:

```
sleep 120
slu postgres ping -H 127.0.0.1 -P 5432 -u $POSTGRES_USER -p $POSTGRES_PASSWORD -n postgres
```

### AWS

Enable AWS secrets engine

```
vault secrets enable aws
```

Prepare AWS keys

```
export AWS_ACCESS_KEY=...
export AWS_SECRET_KEY=...
```

Configure the AWS secrets engine

```
vault write aws/config/root \
  access_key=$AWS_ACCESS_KEY \
  secret_key=$AWS_SECRET_KEY \
  region=eu-central-1
```

Create S3 role

```
vault write aws/roles/s3 \
  credential_type=iam_user \
  policy_document=@examples/aws/s3_policy.json
```

Get credentials

```
vault read aws/creds/s3
```

## Tokens & Leases

### Tokens

Docs: https://developer.hashicorp.com/vault/docs/concepts/tokens

Look up your current token

```
vault token lookup
```

Create a token with a policy and a TTL

```
vault token create -policy=myapp-read -ttl=10m -explicit-max-ttl=1h
```

```
TOKEN=$(vault token create -policy=myapp-read -ttl=10m -explicit-max-ttl=1h -field=token)
```

Look up the token

```
vault token lookup $TOKEN
```

Renew the token (the TTL can't go over `explicit_max_ttl`)

```
vault token renew -increment=30m $TOKEN
```

Revoke the token

```
vault token revoke $TOKEN
```

```
vault token lookup $TOKEN
```

#### Token Accessors

Every token has an **accessor**. You can use it to look up and revoke the token, but not to use the token. It is safe to log and store accessors.

```
ACCESSOR=$(vault token create -policy=myapp-read -field=token_accessor)
```

```
vault token lookup -accessor $ACCESSOR
```

```
vault token revoke -accessor $ACCESSOR
```

List all token accessors

```
vault list auth/token/accessors
```

#### Token Hierarchy

A token is a **child** of the token that created it. When you revoke the parent, all its children are revoked too.

Create a parent token that can create tokens

```
vault policy write token-create - <<EOF
path "auth/token/create" {
  capabilities = ["create", "update"]
}
EOF
```

```
PARENT=$(vault token create -policy=token-create -policy=myapp-read -field=token)
```

Create a child token using the parent token (a child can have only a subset of the parent's policies)

```
CHILD=$(VAULT_TOKEN=$PARENT vault token create -policy=myapp-read -field=token)
```

Revoke the parent

```
vault token revoke $PARENT
```

The child is revoked too

```
vault token lookup $CHILD
```

The `-orphan` flag creates a token without a parent, so it is not revoked with the parent.

```
vault token create -orphan -policy=myapp-read
```

#### Periodic Tokens

A periodic token has no max TTL. It lives as long as it is renewed within the period. It is good for long-running services.

```
vault token create -policy=myapp-read -period=24h
```

### Leases

Docs: https://developer.hashicorp.com/vault/docs/concepts/lease

Every dynamic secret (Postgres credentials, AWS keys, ...) has a **lease**. Read some credentials (from the [Database (Postgres)](#database-postgres) and [AWS](#aws) examples)

```
vault read database/creds/readonly
vault read database/creds/readonly
vault read aws/creds/s3
```

See the `lease_id`, `lease_duration` and `lease_renewable` fields.

List leases

```
vault list sys/leases/lookup/database/creds/readonly
```

```
vault list sys/leases/lookup/aws/creds/s3
```

Look up a lease

```
vault lease lookup database/creds/readonly/<lease_id>
```

Renew a lease (up to the role's `max_ttl`)

```
vault lease renew -increment=1h database/creds/readonly/<lease_id>
```

Revoke a lease. Vault drops the Postgres user immediately.

```
vault lease revoke database/creds/readonly/<lease_id>
```

#### Revoke All Leases with Prefix

This is your **break glass** button. For example, if AWS keys leak, you can revoke all keys created by the `s3` role at once. Vault deletes all those IAM users in AWS.

```
vault lease revoke -prefix aws/creds/s3
```

Revoke all Postgres credentials

```
vault lease revoke -prefix database/creds/readonly
```

Revoke everything from the AWS secrets engine

```
vault lease revoke -prefix aws/
```

Check it

```
vault list sys/leases/lookup/aws/creds/s3
```

## Transit Secrets Engine

Docs: https://developer.hashicorp.com/vault/docs/secrets/transit

**Encryption as a service.** Vault encrypts and decrypts data, but doesn't store it. The application stores the ciphertext in its own database, and the **key never leaves Vault**.

Enable transit

```
vault secrets enable transit
```

Create an encryption key

```
vault write -f transit/keys/myapp
```

```
vault read transit/keys/myapp
```

Encrypt data (the plaintext must be base64 encoded)

```
vault write transit/encrypt/myapp plaintext=$(echo -n "my secret data" | base64)
```

```
CIPHERTEXT=$(vault write -field=ciphertext transit/encrypt/myapp plaintext=$(echo -n "my secret data" | base64))
echo $CIPHERTEXT
```

The ciphertext starts with `vault:v1:`, where `v1` is the version of the key.

Decrypt data

```
vault write -field=plaintext transit/decrypt/myapp ciphertext=$CIPHERTEXT | base64 --decode && echo
```

### Key Rotation

Rotate the key

```
vault write -f transit/keys/myapp/rotate
```

```
vault read transit/keys/myapp
```

New data is encrypted with the new version of the key (`vault:v2:...`)

```
vault write transit/encrypt/myapp plaintext=$(echo -n "my secret data" | base64)
```

Old data still works

```
vault write -field=plaintext transit/decrypt/myapp ciphertext=$CIPHERTEXT | base64 --decode && echo
```

Rewrap old ciphertext with the latest key (Vault doesn't return the plaintext)

```
vault write transit/rewrap/myapp ciphertext=$CIPHERTEXT
```

Disable decryption with old versions of the key

```
vault write transit/keys/myapp/config min_decryption_version=2
```

```
vault write transit/decrypt/myapp ciphertext=$CIPHERTEXT
```

### Policy for Application

The application can encrypt and decrypt, but it can't read, export or rotate the key.

```
vault policy write myapp-transit - <<EOF
path "transit/encrypt/myapp" {
  capabilities = ["update"]
}
path "transit/decrypt/myapp" {
  capabilities = ["update"]
}
EOF
```

## PKI Secrets Engine

Docs:

- https://developer.hashicorp.com/vault/docs/secrets/pki
- https://developer.hashicorp.com/vault/tutorials/pki/pki-engine

Vault works as a **certificate authority**. It issues short-lived TLS certificates on demand, so you don't have to rotate certificates by hand. Use it for internal services, mTLS, service mesh, and so on.

We will create a **root CA** and an **intermediate CA** signed by the root CA. The intermediate CA issues the certificates.

### Root CA

```
vault secrets enable pki
```

```
vault secrets tune -max-lease-ttl=87600h pki
```

```
vault write -field=certificate pki/root/generate/internal \
  common_name="Example Root CA" \
  ttl=87600h > root_ca.local.crt
```

```
vault write pki/config/urls \
  issuing_certificates="$VAULT_ADDR/v1/pki/ca" \
  crl_distribution_points="$VAULT_ADDR/v1/pki/crl"
```

### Intermediate CA

```
vault secrets enable -path=pki_int pki
```

```
vault secrets tune -max-lease-ttl=43800h pki_int
```

Generate a CSR for the intermediate CA

```
vault write -field=csr pki_int/intermediate/generate/internal \
  common_name="Example Intermediate CA" > pki_int.local.csr
```

Sign it with the root CA

```
vault write -field=certificate pki/root/sign-intermediate \
  csr=@pki_int.local.csr \
  format=pem_bundle \
  ttl=43800h > pki_int.local.crt
```

Import the signed certificate

```
vault write pki_int/intermediate/set-signed certificate=@pki_int.local.crt
```

```
vault write pki_int/config/urls \
  issuing_certificates="$VAULT_ADDR/v1/pki_int/ca" \
  crl_distribution_points="$VAULT_ADDR/v1/pki_int/crl"
```

### Role

The role says what certificates can be issued.

```
vault write pki_int/roles/example-com \
  allowed_domains=example.com \
  allow_subdomains=true \
  max_ttl=72h
```

### Issue Certificate

```
vault write pki_int/issue/example-com common_name=www.example.com ttl=24h
```

Save it to JSON and inspect the certificate

```
vault write -format=json pki_int/issue/example-com common_name=www.example.com ttl=24h > cert.local.json
```

```
jq -r .data.certificate cert.local.json | openssl x509 -noout -subject -issuer -enddate
```

Try a domain that is not allowed

```
vault write pki_int/issue/example-com common_name=www.google.com
```

### Revoke Certificate

```
vault write pki_int/revoke serial_number=$(jq -r .data.serial_number cert.local.json)
```

```
vault list pki_int/certs/revoked
```

Cleanup

```
rm root_ca.local.crt pki_int.local.csr pki_int.local.crt cert.local.json
```

## Production Vault on Kubernetes

Docs:

- [Highly Available Vault Cluster with Integrated Storage (Raft)](https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/ha-with-raft)

Install production Vault

```
make k8s-prod-server
```

Init

```
vault operator init
```

```
kubectl exec -ti -n vault vault-0 -- vault operator init
```

Or init and save info into `json`

```
vault operator init -format=json > vault_init.local.json
```

```
kubectl exec -ti -n vault vault-0 -- vault operator init -format=json > vault_init.local.json
```

Unseal

```
vault operator unseal
```

```
kubectl exec -ti -n vault vault-0 -- vault operator unseal
```

Add nodes to cluster

```
vault operator raft join http://vault-0.vault-internal:8200
```

```
kubectl exec -ti -n vault vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
```

and unseal

```
vault operator unseal
```

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

### Unseal All Vault Pods from JSON

```
kubectl exec -ti -n vault vault-0 -- vault operator unseal $(cat vault_init.local.json | jq -r '.unseal_keys_b64[0]')
kubectl exec -ti -n vault vault-0 -- vault operator unseal $(cat vault_init.local.json | jq -r '.unseal_keys_b64[1]')
kubectl exec -ti -n vault vault-0 -- vault operator unseal $(cat vault_init.local.json | jq -r '.unseal_keys_b64[2]')

kubectl exec -ti -n vault vault-1 -- vault operator unseal $(cat vault_init.local.json | jq -r '.unseal_keys_b64[0]')
kubectl exec -ti -n vault vault-1 -- vault operator unseal $(cat vault_init.local.json | jq -r '.unseal_keys_b64[1]')
kubectl exec -ti -n vault vault-1 -- vault operator unseal $(cat vault_init.local.json | jq -r '.unseal_keys_b64[2]')

kubectl exec -ti -n vault vault-2 -- vault operator unseal $(cat vault_init.local.json | jq -r '.unseal_keys_b64[0]')
kubectl exec -ti -n vault vault-2 -- vault operator unseal $(cat vault_init.local.json | jq -r '.unseal_keys_b64[1]')
kubectl exec -ti -n vault vault-2 -- vault operator unseal $(cat vault_init.local.json | jq -r '.unseal_keys_b64[2]')
```

## Backup & Restore

### Backup

```
vault operator raft snapshot save backup.snap
```

### Restore

Create new cluster, unseal & login to it.

```
vault operator raft snapshot restore -force backup.snap
```

### Backup using Tergum

- Tergum - Backup tool - https://github.com/sikalabs/tergum
- Blog post about backup - https://ondrej-sika.cz/blog/tergum-v0.30.0

Copy example config & edit token

```
make tergum-copy-config
vim examples/tergum/tergum.yml
```

Run backup

```
tergum backup --config examples/tergum/tergum.yml
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

### Enable Kubernetes Auth

```
vault auth enable kubernetes
```

### Configure Kubernetes Auth

```
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc.cluster.local:443"
```

### Create Secrets Engine

```
vault secrets enable -path=test kv-v2
```

### Add Secret

```
vault kv put test/example username=foo password=bar
```

### Create Policy

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

### Create Vault Auth

```
kubectl apply -f examples/vault_secrets_operator/vaultauth.yml
```

### Create Vault Secret

```
kubectl apply -f examples/vault_secrets_operator/vaultstaticsecret.yml
```

### Check Secret

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

Enable the OIDC authentication method in Vault by running the following command:

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

_Do you like the course? Write me a recommendation on Twitter (with handle `@ondrejsika`) and LinkedIn (add me [/in/ondrejsika](https://www.linkedin.com/in/ondrejsika/) and I'll send you a request for recommendation). **Thanks**._

Want to go for a beer or do some work together? Just [book me](https://book-me.sika.io) :)
