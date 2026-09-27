terraform {
    required_providers {
        google = {
        source  = "hashicorp/google"
        version = "8.3.0"
        }
    }

    backend "gcs" {
        bucket = "539d6ed30d7a5ada-terraform-remote-backend"
    }
}

provider "google" {
    # Configuration options
    project = "playground-s-11-180f8608"
    region = "us-central1"
}
