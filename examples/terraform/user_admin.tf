resource "random_string" "userpass_admin_password" {
  length  = 8
  special = false
}

resource "vault_identity_entity" "admin" {
  name = "admin-entity"
  policies = [
    vault_policy.super-admin.name,
  ]
}

resource "vault_generic_endpoint" "userpass_admin" {
  depends_on = [
    vault_auth_backend.userpass,
  ]
  path                 = "auth/userpass/users/admin"
  ignore_absent_fields = true

  data_json = jsonencode(
    {
      "password" = random_string.userpass_admin_password.result
    }
  )
}

resource "vault_identity_entity_alias" "userpass_admin" {
  depends_on = [
    vault_generic_endpoint.userpass_admin,
  ]
  name           = "admin"
  mount_accessor = vault_auth_backend.userpass.accessor
  canonical_id   = vault_identity_entity.admin.id
}

output "userpass_admin_password" {
  value = random_string.userpass_admin_password.result
}
