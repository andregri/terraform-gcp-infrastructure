resource "google_project_service_identity" "secret_manager" {
  provider = google-beta

  project = var.project_id
  service = "secretmanager.googleapis.com"
}

data "google_project" "this" {
  project_id = var.project_id
}

resource "google_project_iam_binding" "pod_sa_secret_access" {
  project = var.project_id
  members = ["principal://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${var.project_id}.svc.id.goog/subject/ns/default/sa/${var.kubernetes_service_account}"]
  role    = "roles/secretmanager.secretAccessor"
}