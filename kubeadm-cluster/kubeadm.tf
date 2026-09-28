locals {
  zone = "us-central1-c"
  nodes = [ "control-plane0", "worker0" ]
  user = "${split("@", data.google_client_openid_userinfo.me.email)[0]}_linuxacade"
}

data "google_client_openid_userinfo" "me" {
}

resource "google_service_account" "kubeadm" {
  for_each = toset(local.nodes)
  account_id   = "${each.value}-sa"
  display_name = "Service Account for Kubeadm VM Instance"
}

resource "google_compute_instance" "kubeadm" {
  for_each = toset(local.nodes)
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
    echo "hi" > hello.txt && \
    ln -s /tmp/ansible-roles /etc && \
    ansible-playbook --inventory localhost, --connection local --extra-vars "target_hosts=localhost" playbooks/kubeadm-tools/containerd-kubeadm.yaml
  EOT

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.kubeadm[each.key].email
    scopes = ["cloud-platform"]
  }

  provisioner "local-exec" {
    when = destroy
    command = "sed -i '' '/^${each.key}/d' \"$HOME/.ssh/known_hosts\""
  }
}

resource "local_file" "inventory" {
  filename = "${path.module}/inventory.yaml"
  content = yamlencode({
    all : {
      children: {
        control_plane: {
          hosts: {
            for i, node in local.nodes :
              node => {
                private_ip : google_compute_instance.kubeadm[node].network_interface.0.network_ip,
                ansible_user: local.user,
                ansible_host: node,
                ansible_port: 22,
                gcp_project: google_compute_instance.kubeadm[node].project,
                gcp_zone: google_compute_instance.kubeadm[node].zone,
                ansible_ssh_common_args: "-o StrictHostKeyChecking=accept-new -o ProxyCommand=\"gcloud compute start-iap-tunnel %h %p --listen-on-stdin --project ${google_compute_instance.kubeadm[node].project} --zone ${google_compute_instance.kubeadm[node].zone}\"",
                ansible_private_key_file: "~/.ssh/google_compute_engine"
              } if strcontains(node, "control-plane")
          }
        },
        workers: {
          hosts: {
            for i, node in local.nodes :
              node => {
                private_ip : google_compute_instance.kubeadm[node].network_interface.0.network_ip,
                ansible_user: local.user,
                ansible_host: node,
                ansible_port: 22,
                gcp_project: google_compute_instance.kubeadm[node].project,
                gcp_zone: google_compute_instance.kubeadm[node].zone,
                ansible_ssh_common_args: "-o StrictHostKeyChecking=accept-new -o ProxyCommand=\"gcloud compute start-iap-tunnel %h %p --listen-on-stdin --project ${google_compute_instance.kubeadm[node].project} --zone ${google_compute_instance.kubeadm[node].zone}\"",
                ansible_private_key_file: "~/.ssh/google_compute_engine"
              }  if strcontains(node, "worker")
          }
        } 
      }
    }
  })
}
