output "ssh_login" {
  value = "gcloud compute ssh ${google_compute_instance.kubeadm["control-plane0"].name} --tunnel-through-iap --project ${google_compute_instance.kubeadm["control-plane0"].project} --zone ${google_compute_instance.kubeadm["control-plane0"].zone}"
}

output "gcp_user" {
  value = local.user
}

output "start_etcd" {
  value = "etcd --listen-client-urls=http://${google_compute_instance.etcd["etcd0"].network_interface.0.network_ip}:2379 --advertise-client-urls=http://${google_compute_instance.etcd["etcd0"].network_interface.0.network_ip}:2379"
}