output "ssh_login" {
  value = "gcloud compute ssh ${google_compute_instance.default.name} --tunnel-through-iap --project ${google_compute_instance.default.project} --zone ${google_compute_instance.default.zone}"
}