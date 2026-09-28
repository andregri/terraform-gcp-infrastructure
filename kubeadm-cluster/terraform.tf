terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.3.0"
    }
  }

  backend "gcs" {
    bucket = "ed4f75942b29a8f9-terraform-remote-backend"
  }
}

provider "google" {
  # Configuration options
  project = "playground-s-11-ad2314a6"
  region  = "us-central1"
}
