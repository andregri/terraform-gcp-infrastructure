locals {
    terraform_module_dirs = [
        "single-vm"
    ]
}

resource "random_id" "default" {
  byte_length = 8
}

resource "google_storage_bucket" "default" {
  name     = "${random_id.default.hex}-terraform-remote-backend"
  location = "US"
  project  = var.project_id

  force_destroy               = false
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }
}

resource "local_file" "terraform_tf" {
    for_each = toset(local.terraform_module_dirs)
    file_permission = "0644"
    filename = "${path.module}/../${each.value}/terraform.tf"

    content = <<-EOT
        terraform {
            required_providers {
                google = {
                source  = "hashicorp/google"
                version = "8.3.0"
                }
            }

            backend "gcs" {
                bucket = "${google_storage_bucket.default.name}"
            }
        }

        provider "google" {
            # Configuration options
            project = "${var.project_id}"
            region = "us-central1"
        }
    EOT
}