provider "google" {
  version = "= 3.59.0"

  credentials = file(var.google_creds_path)
  project     = var.project_id
}

provider "google-beta" {
  version = "= 3.59.0"

  credentials = file(var.google_creds_path)
  project     = var.project_id
}

terraform {
  backend "gcs" {
    bucket = "phd-project-tf-state"
  }
}

data "google_client_config" "default" {}

provider "kubernetes" {
  version = "1.13.2"

  load_config_file       = false
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
  host                   = "https://${module.gke.endpoint}"
}

provider "helm" {
  version = "~> 1.3"

  kubernetes {
    load_config_file       = false
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)
    host                   = "https://${module.gke.endpoint}"
  }
}