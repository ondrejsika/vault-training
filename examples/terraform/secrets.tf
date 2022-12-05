resource "vault_generic_secret" "foo_bar" {
  depends_on = [
    vault_mount.kv2-secret,
  ]
  lifecycle {
    ignore_changes = [
      data_json,
    ]
  }

  path = "secret/foo/bar"

  data_json = sensitive(jsonencode(
    {
      "ACCESS_KEY"  = "CHANGE_ME"
      "SECRET_KEY"  = "CHANGE_ME"
      "REGION"      = "CHANGE_ME"
      "ENDPOINT"    = "CHANGE_ME"
      "BUCKET_NAME" = "CHANGE_ME"
    }
  ))
}
