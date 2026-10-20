// vault policy write token-create-sudo examples/policies/token_create_sudo.hcl

path "auth/token/create" {
  capabilities = [
    "create", "update",
    "sudo", // for -orphan token
  ]
}