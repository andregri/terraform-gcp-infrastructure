terraform {
    required_providers {
        google = {
        source  = "hashicorp/google"
        version = "8.3.0"
        }
    }

    backend "gcs" {
        bucket = "2931d044721f4c0c-terraform-remote-backend"
    }
}

provider "google" {
    # Configuration options
    project = "playground-s-11-63e65064"
    region = "us-central1"
}
