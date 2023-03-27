resource "vault_jwt_auth_backend" "keycloak_oidc" {
  description        = "Keycloak OIDC authentication"
  path               = "oidc"
  oidc_discovery_url = "https://sso.sikademo.com/realms/example"
  oidc_client_id     = "example"
  oidc_client_secret = "example"
  default_role       = "default"
}

resource "vault_jwt_auth_backend_role" "default" {
  backend    = vault_jwt_auth_backend.keycloak_oidc.path
  role_name  = vault_jwt_auth_backend.keycloak_oidc.default_role
  user_claim = "sub"
  bound_audiences = [
    vault_jwt_auth_backend.keycloak_oidc.oidc_client_id,
  ]
  allowed_redirect_uris = [
    "http://localhost:8250/oidc/callback",
    "http://localhost:8200/ui/vault/auth/oidc/oidc/callback",
    "https://vault.k8s.sikademo.com/ui/vault/auth/oidc/oidc/callback",
  ]
  token_policies = [
    vault_policy.read-all-secret.name,
  ]
}

resource "vault_identity_group" "admin" {
  name = "admin"
  type = "external"
  policies = [
    vault_policy.super-admin.name,
  ]
}

resource "vault_identity_group" "read-all-secret" {
  name = "reader"
  type = "external"
  policies = [
    vault_policy.read-all-secret.name,
  ]
}

resource "vault_identity_group_alias" "admin" {
  name           = vault_identity_group.admin.name
  canonical_id   = vault_identity_group.admin.id
  mount_accessor = vault_jwt_auth_backend.keycloak_oidc.accessor
}

resource "vault_identity_group_alias" "read-all-secret" {
  name           = vault_identity_group.read-all-secret.name
  canonical_id   = vault_identity_group.read-all-secret.id
  mount_accessor = vault_jwt_auth_backend.keycloak_oidc.accessor
}
