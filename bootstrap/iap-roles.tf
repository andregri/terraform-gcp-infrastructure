data "google_client_openid_userinfo" "me" {
}

locals {
    grant_iap_secured_tunnel_users_email = [
        data.google_client_openid_userinfo.me.email
    ]
}

resource "google_project_iam_binding" "iap-tunnel-user" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"

  members = [ for email in local.grant_iap_secured_tunnel_users_email : "user:${email}" ]
}