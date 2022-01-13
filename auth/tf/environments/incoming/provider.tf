provider "google" {
  credentials = file(var.google_creds_path)
  project     = var.cluster_project
}

provider "google-beta" {
  credentials = file(var.google_creds_path)
  project     = var.cluster_project
}

terraform {
  backend "gcs" {}
}
