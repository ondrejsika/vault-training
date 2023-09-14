locals {
  allowed_redirect_uris = [
    "http://127.0.0.1:8250/oidc/callback",
    "http://127.0.0.1:8200/ui/vault/auth/oidc/oidc/callback",

    "http://localhost:8250/oidc/callback",
    "http://localhost:8200/ui/vault/auth/oidc/oidc/callback",

    "https://vault.k8s.sikademo.com/ui/vault/auth/oidc/oidc/callback",
  ]
}

resource "vault_jwt_auth_backend" "keycloak_oidc" {
  description        = "Keycloak OIDC authentication"
  path               = "oidc"
  oidc_discovery_url = "https://sso.sikademo.com/realms/sikademo"
  oidc_client_id     = "vault"
  oidc_client_secret = "vault"
  default_role       = "default"
}

resource "vault_jwt_auth_backend_role" "default" {
  backend    = vault_jwt_auth_backend.keycloak_oidc.path
  role_name  = vault_jwt_auth_backend.keycloak_oidc.default_role
  user_claim = "sub"
  bound_audiences = [
    vault_jwt_auth_backend.keycloak_oidc.oidc_client_id,
  ]
  allowed_redirect_uris = local.allowed_redirect_uris
  token_policies = [
    vault_policy.read-all-secret.name,
  ]
}

resource "vault_jwt_auth_backend_role" "admin" {
  backend      = vault_jwt_auth_backend.keycloak_oidc.path
  role_name    = "admin"
  user_claim   = "sub"
  groups_claim = "groups"
  bound_claims = {
    "groups" = "vault-admin"
  }
  bound_audiences = [
    vault_jwt_auth_backend.keycloak_oidc.oidc_client_id,
  ]
  allowed_redirect_uris = local.allowed_redirect_uris
  token_policies = [
    vault_policy.super-admin.name,
  ]
}

resource "vault_identity_group" "admin" {
  name = "vault-admin"
  type = "external"
  policies = [
    vault_policy.super-admin.name,
  ]
}

resource "vault_identity_group" "read-all-secret" {
  name = "vault-reader"
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
