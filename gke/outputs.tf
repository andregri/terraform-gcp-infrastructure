output "cmd_get_credentials" {
  value = "gcloud container clusters get-credentials ${google_container_cluster.zonal.name} --location=${var.location}-a"
}