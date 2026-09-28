locals {
  etcd_nodes_count = 1
  etcd_nodes       = [for i in range(local.etcd_nodes_count) : "etcd${i}"]
}

resource "google_service_account" "etcd" {
  for_each     = toset(local.etcd_nodes)
  account_id   = "${each.value}-sa"
  display_name = "Service Account for etcd VM Instance"
}

resource "google_compute_instance" "etcd" {
  for_each     = toset(local.etcd_nodes)
  name         = each.value
  machine_type = "e2-standard-2"
  zone         = local.zone

  tags = ["role", each.value]

  boot_disk {
    initialize_params {
      image = "projects/debian-cloud/global/images/debian-13-trixie-v20260908"
      labels = {
        role = each.value
      }
    }
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

  metadata_startup_script = <<-EOT
    #!/bin/bash
    set -euxo pipefail
    apt update && \
    apt install -y ansible git && \
    git clone https://github.com/andregri/ansible-roles.git /tmp/ansible-roles && \
    cd /tmp/ansible-roles && \
    ansible --inventory localhost, all --connection local --become --module-name include_role --args name=etcd
  EOT

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.etcd[each.key].email
    scopes = ["cloud-platform"]
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '' '/^${each.key}/d' \"$HOME/.ssh/known_hosts\""
  }
}