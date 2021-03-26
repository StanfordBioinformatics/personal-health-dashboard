data "google_compute_subnetwork" "subnetwork" {
  name    = var.subnetwork
  project = var.project_id
  region  = var.region
}

data "google_compute_network" "network" {
  name    = var.network
  project = var.project_id
}