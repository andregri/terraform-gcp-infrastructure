variable "location" {
  type    = string
  default = "us-central1"
}

variable "kubernetes_service_account" {
  type    = string
  default = "mypodserviceaccount"
}

variable "project_id" {
  type = string
}