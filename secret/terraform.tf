terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "8.3.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "8.4.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.3.2"
    }
  }
}

provider "google" {
  # Configuration options
  region = "us-central1"
}

provider "google-beta" {
  region = "us-central1"
}