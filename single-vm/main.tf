locals {
  zone = "us-central1-c"
}

resource "google_service_account" "default" {
  account_id   = "my-custom-sa"
  display_name = "Custom SA for VM Instance"
}

resource "google_compute_instance" "default" {
  name         = "my-instance"
  machine_type = "e2-standard-2"
  zone         = local.zone

  tags = ["foo", "bar"]

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/debian-13-trixie-v20260908"
      labels = {
        my_label = "value"
      }
    }
  }

  attached_disk {
    source = google_compute_disk.data.self_link
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_disk" "data" {
  name  = "test-disk"
  type  = "pd-ssd"
  zone  = local.zone
  size  = 8

  physical_block_size_bytes = 4096
}