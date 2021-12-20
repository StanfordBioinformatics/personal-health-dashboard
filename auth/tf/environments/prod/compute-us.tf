module "east_cluster" {
  source = "../../modules/cluster"

  cluster_project = var.cluster_project
  prefix          = var.prefix
  region          = "us-east1"

  network   = google_compute_network.network.self_link
  port_name = local.portName
  port_num  = local.port

  num_zones = var.num_zones
}

module "east_workloads" {
  source                 = "../../modules/workloads"
  host                   = module.east_cluster.host
  client_certificate     = module.east_cluster.client_certificate
  client_key             = module.east_cluster.client_key
  cluster_ca_certificate = module.east_cluster.cluster_ca_certificate
  nodes_ready            = module.east_cluster.nodes_ready
  port_name              = local.portName
  port_num               = local.port
  region                 = "us-east1"
  cluster_name           = module.east_cluster.name
  cluster_project        = var.cluster_project
  sftp_permissions       = var.sftp_permissions
  gcs_keys_bucket        = var.gcs_keys_bucket
  network                = google_compute_network.network.name
  zones                  = module.east_cluster.zones
}

module "west_cluster" {
  source = "../../modules/cluster"

  cluster_project = var.cluster_project
  prefix          = var.prefix
  region          = "us-west1"

  network       = google_compute_network.network.self_link
  subnet_prefix = "1"
  port_name     = local.portName
  port_num      = local.port

  num_zones = var.num_zones
}

module "west_workloads" {
  source                 = "../../modules/workloads"
  host                   = module.west_cluster.host
  client_certificate     = module.west_cluster.client_certificate
  client_key             = module.west_cluster.client_key
  cluster_ca_certificate = module.west_cluster.cluster_ca_certificate
  nodes_ready            = module.west_cluster.nodes_ready
  port_name              = local.portName
  port_num               = local.port
  region                 = "us-west1"
  cluster_name           = module.west_cluster.name
  cluster_project        = var.cluster_project
  sftp_permissions       = var.sftp_permissions
  gcs_keys_bucket        = var.gcs_keys_bucket
  network                = google_compute_network.network.name
  zones                  = module.west_cluster.zones
}

