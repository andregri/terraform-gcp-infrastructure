terraform {
    required_providers {
        google = {
        source  = "hashicorp/google"
        version = "8.3.0"
        }
    }

    backend "gcs" {
        bucket = "b5b883c4d36b7751-terraform-remote-backend"
    }
}

provider "google" {
    # Configuration options
    project = "playground-s-11-59c1d642"
    region = "us-central1"
}
