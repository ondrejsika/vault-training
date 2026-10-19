# Read secrets of myapp in KV v2 mounted at secret/

# vault kv get secret/myapp/...
path "secret/data/myapp/*" {
  capabilities = ["read"]
}

# vault kv list secret/myapp/
path "secret/metadata/myapp/*" {
  capabilities = ["list"]
}
