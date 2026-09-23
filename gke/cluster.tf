resource "google_service_account" "default" {
  account_id   = "service-account-id"
  display_name = "Service Account"
  project      = var.project_id
}

resource "null_resource" "enable_containers" {
  provisioner "local-exec" {
    command = "gcloud services enable container.googleapis.com --project=${var.project_id}"
    when    = create
  }
}

resource "google_container_cluster" "zonal" {
  depends_on = [ null_resource.enable_containers ]

  name     = "lab"
  location = "us-central1-a"
  project  = var.project_id

  deletion_protection = false

  remove_default_node_pool = true
  initial_node_count       = 1

  secret_manager_config {
    enabled = true
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }
}

resource "google_container_node_pool" "default_pool" {
  name           = "default-pool"
  node_locations = ["us-central1-a", "us-central1-b", "us-central1-c"]
  cluster        = google_container_cluster.zonal.id
  project        = var.project_id
  node_count     = 1 # Usa questo OPPURE initial_node_count, non entrambi insieme
  version        = "1.35.6-gke.1250000"

  node_config {
    machine_type = "e2-standard-2"
    image_type   = "COS_CONTAINERD"

    # Gestione del disco (Configurata correttamente)
    disk_size_gb = 100
    disk_type    = "pd-balanced"

    # Account di servizio e permessi
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform" # Questo include già tutti gli altri scope inseriti in precedenza
    ]

    preemptible = false
  }

  upgrade_settings {
    strategy        = "SURGE"
    max_surge       = 0
    max_unavailable = 1
  }
}