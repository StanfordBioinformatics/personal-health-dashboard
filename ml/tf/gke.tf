module "gke" {
  source                     = "terraform-google-modules/kubernetes-engine/google//modules/safer-cluster"
  version                    = "14.0.0"
  project_id                 = var.project_id
  name                       = "${var.prefix}-cluster"
  regional                   = var.cluster.regional
  region                     = var.cluster.region
  zones                      = [var.cluster.zone]
  network                    = var.network
  subnetwork                 = var.subnetwork
  http_load_balancing        = true
  horizontal_pod_autoscaling = true
  ip_range_pods              = var.cluster.ip_range_pods
  ip_range_services          = var.cluster.ip_range_services
  release_channel            = "STABLE"
  initial_node_count         = 0
  enable_pod_security_policy = var.cluster.enable_pod_security_policy
  grant_registry_access      = var.cluster.grant_registry_access
  default_max_pods_per_node  = var.cluster.default_max_pods_per_node

  master_authorized_networks = [
    {
      cidr_block   = data.google_compute_subnetwork.subnetwork.ip_cidr_range
      display_name = "VPC"
    },
  ]

  node_pools = var.node_pools

  node_pools_labels = var.node_pools_labels

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly"
    ]

    default-node-pool = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}