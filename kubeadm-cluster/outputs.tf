output "ssh_login" {
  value = "gcloud compute ssh ${google_compute_instance.kubeadm["control-plane0"].name} --tunnel-through-iap --project ${google_compute_instance.kubeadm["control-plane0"].project} --zone ${google_compute_instance.kubeadm["control-plane0"].zone}"
}

output "gcp_user" {
  value = local.user
}