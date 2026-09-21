terraform {
    required_providers {
        google = {
        source  = "hashicorp/google"
        version = "8.3.0"
        }
    }

    backend "gcs" {
        bucket = "6b5bee699fad740a-terraform-remote-backend"
    }
}

provider "google" {
    # Configuration options
    project = "playground-s-11-657640ae"
    region = "us-central1"
}
