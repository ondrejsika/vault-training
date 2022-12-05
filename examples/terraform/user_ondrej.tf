resource "random_string" "userpass_ondrej_password" {
  length  = 8
  special = false
}

resource "vault_identity_entity" "ondrej" {
  name = "ondrej-entity"
  policies = [
    vault_policy.read-all-secret.name,
  ]
}

resource "vault_generic_endpoint" "userpass_ondrej" {
  depends_on = [
    vault_auth_backend.userpass,
  ]
  path                 = "auth/userpass/users/ondrej"
  ignore_absent_fields = true

  data_json = jsonencode(
    {
      "password" = random_string.userpass_ondrej_password.result
    }
  )
}

resource "vault_identity_entity_alias" "userpass_ondrej" {
  depends_on = [
    vault_generic_endpoint.userpass_ondrej,
  ]
  name           = "ondrej"
  mount_accessor = vault_auth_backend.userpass.accessor
  canonical_id   = vault_identity_entity.ondrej.id
}

output "userpass_ondrej_password" {
  value = random_string.userpass_ondrej_password.result
}
