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
      "ACCESS_KEY"  = "__CHANGE_ME__"
      "SECRET_KEY"  = "__CHANGE_ME__"
      "REGION"      = "__CHANGE_ME__"
      "ENDPOINT"    = "__CHANGE_ME__"
      "BUCKET_NAME" = "__CHANGE_ME__"
    }
  ))
}
