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
