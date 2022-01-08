resource "google_compute_network" "network" {
  name                    = "${var.prefix}-net"
  project                 = var.cluster_project
  auto_create_subnetworks = false
}
