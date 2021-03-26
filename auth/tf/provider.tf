provider "google" {
  version = "= 3.42"

  credentials = file(var.google_creds_path)
  project     = var.cluster_project
}

provider "google-beta" {
  version = "= 3.42"

  credentials = file(var.google_creds_path)
  project     = var.cluster_project
}

terraform {
  backend "gcs" {
    bucket = "phd-project-tf-state"
  }
}