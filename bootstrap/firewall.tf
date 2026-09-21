data "google_compute_network" "default" {
  name = "default"
  project = var.project_id
}

resource "google_compute_firewall" "allow-ssh-from-iap" {
  name    = "allow-ssh-from-iap"
  network = data.google_compute_network.default.self_link
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  direction = "INGRESS"

  source_ranges = [ "35.235.240.0/20" ]
}
