# Vault server which is auto-unsealed by the transit secrets engine
# of another Vault (the dev server running on 127.0.0.1:8200)

ui           = true
api_addr     = "http://127.0.0.1:8300"
cluster_addr = "http://127.0.0.1:8301"

storage "raft" {
  path    = "./tmp/vault-auto-unseal"
  node_id = "node1"
}

listener "tcp" {
  address         = "127.0.0.1:8300"
  cluster_address = "127.0.0.1:8301"
  tls_disable     = true
}

seal "transit" {
  address    = "http://127.0.0.1:8200"
  # token is taken from the VAULT_TOKEN environment variable
  # (VAULT_ADDR, if set, overrides the address above)
  key_name   = "autounseal"
  mount_path = "transit/"
}
