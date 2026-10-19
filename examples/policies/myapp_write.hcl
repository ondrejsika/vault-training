# Manage secrets of myapp in KV v2 mounted at secret/

# vault kv get / put / patch secret/myapp/...
path "secret/data/myapp/*" {
  capabilities = ["create", "read", "update", "patch", "delete"]
}

# vault kv list, vault kv metadata get / delete secret/myapp/...
path "secret/metadata/myapp/*" {
  capabilities = ["read", "list", "delete"]
}

# vault kv delete / undelete / destroy -versions ... secret/myapp/...
path "secret/delete/myapp/*" {
  capabilities = ["update"]
}
path "secret/undelete/myapp/*" {
  capabilities = ["update"]
}
path "secret/destroy/myapp/*" {
  capabilities = ["update"]
}
