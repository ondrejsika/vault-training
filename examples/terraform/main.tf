terraform {
  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "3.4.1"
    }
    random = {
      source = "hashicorp/random"
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

resource "vault_mount" "kv2-secret" {
  path = "secret"
  type = "kv-v2"
}

variable "aws_access_key" {}
variable "aws_secret_key" {}

resource "vault_aws_secret_backend" "aws" {
  path       = "aws"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "vault_aws_secret_backend_role" "s3" {
  backend         = vault_aws_secret_backend.aws.path
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
