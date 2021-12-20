module "eu_north_cluster" {
  source = "../../modules/cluster"

  cluster_project = var.cluster_project
  prefix          = var.prefix
  region          = "europe-north1"

  network       = google_compute_network.network.self_link
  subnet_prefix = "2"
  port_name     = local.portName
  port_num      = local.port

  num_zones = var.num_zones
}

module "eu_north_workloads" {
  source                 = "../../modules/workloads"
  host                   = module.eu_north_cluster.host
  client_certificate     = module.eu_north_cluster.client_certificate
  client_key             = module.eu_north_cluster.client_key
  cluster_ca_certificate = module.eu_north_cluster.cluster_ca_certificate
  nodes_ready            = module.eu_north_cluster.nodes_ready
  port_name              = local.portName
  port_num               = local.port
  region                 = "europe-north1"
  cluster_name           = module.eu_north_cluster.name
  cluster_project        = var.cluster_project
  sftp_permissions       = var.sftp_permissions
  gcs_keys_bucket        = var.gcs_keys_bucket
  network                = google_compute_network.network.name
  zones                  = module.eu_north_cluster.zones
}
