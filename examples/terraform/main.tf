terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "3.4.1"
    }
  }
}

variable "vault_address" {
  type = string
}

variable "vault_token" {
  type = string
}

provider "vault" {
  address = var.vault_address
  token   = var.vault_token
}

resource "vault_auth_backend" "userpass" {
  type = "userpass"
}

resource "vault_policy" "super-admin" {
  name = "super-admin"

  policy = <<EOT
path "*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOT
}

resource "vault_policy" "read-all-secret" {
  name = "read-all-secret"

  policy = <<EOT
path "secret/metadata/*" {
  capabilities = ["list", "read"]
}
path "secret/data/*" {
  capabilities = ["read", "list"]
}
EOT
}

resource "vault_policy" "s3" {
  name = "s3"

  policy = <<EOT
path "aws/creds/s3" {
  capabilities = ["read"]
}
EOT
}

resource "vault_mount" "kv2-secret" {
  path = "secret"
  type = "kv-v2"
}

resource "vault_mount" "aws" {
  path = "aws"
  type = "aws"
}

resource "vault_aws_secret_backend_role" "s3" {
  backend         = "aws"
  name            = "s3"
  credential_type = "iam_user"

  policy_document = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": "*"
    }
  ]
}
EOT
}

resource "vault_identity_entity" "admin" {
  name = "admin-user"
  policies = [
    vault_policy.super-admin.name,
  ]
}

resource "vault_identity_entity_alias" "admin" {
  name           = vault_identity_entity.admin.name
  mount_accessor = vault_auth_backend.userpass.accessor
  canonical_id   = vault_identity_entity.admin.id
}


resource "vault_identity_entity" "ondrej" {
  name = "ondrej-entity"
  policies = [
    vault_policy.read-all-secret.name,
  ]
}

resource "vault_identity_entity_alias" "ondrej" {
  name           = "ondrej"
  mount_accessor = vault_auth_backend.userpass.accessor
  canonical_id   = vault_identity_entity.ondrej.id
}

resource "vault_identity_entity" "s3" {
  name = "s3-entity"
  policies = [
    vault_policy.s3.name,
  ]
}

resource "vault_identity_entity_alias" "s3" {
  name           = "s3"
  mount_accessor = vault_auth_backend.userpass.accessor
  canonical_id   = vault_identity_entity.s3.id
}
