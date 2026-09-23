resource "null_resource" "enable_secret_manager" {
  provisioner "local-exec" {
    command = "gcloud services enable secretmanager.googleapis.com"
    when    = create
  }
}

resource "google_secret_manager_secret" "default" {
  depends_on = [null_resource.enable_secret_manager]

  secret_id = "test"
  project   = var.project_id

  replication {
    user_managed {
      replicas {
        location = var.location
      }
    }
  }

  rotation {
    next_rotation_time = "2026-10-01T15:01:23Z"
    rotation_period    = "3600s"
  }

  topics {
    name = "projects/${var.project_id}/topics/${google_pubsub_topic.default.name}"
  }

  deletion_protection = false
}

resource "google_pubsub_topic" "default" {
  name    = "secret-topic"
  project = var.project_id
}

resource "google_pubsub_topic_iam_binding" "default" {
  project = var.project_id
  topic   = google_pubsub_topic.default.name
  members = ["serviceAccount:${google_project_service_identity.secret_manager.email}"]
  role    = "roles/pubsub.publisher"
}
