// Get zones for region.
data "google_compute_zones" "available" {
  region = var.region
}

// Pool configuration
locals {
  clusterName = "${var.prefix}-${var.region}"
  zones       = slice(data.google_compute_zones.available.names, 0, min(var.num_zones, length(data.google_compute_zones.available.names)))

  defaultVersion = "1.16.13-gke.1"
  oauth_scopes = [
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring",
    "https://www.googleapis.com/auth/servicecontrol",
    "https://www.googleapis.com/auth/service.management.readonly",
    "https://www.googleapis.com/auth/trace.append",
  ]
}

resource "google_container_cluster" "phd_cluster" {
  provider = google-beta

  name        = local.clusterName
  description = "PHD infrastructure for ${var.region}"

  location       = var.region
  node_locations = local.zones

  network    = var.network
  subnetwork = google_compute_subnetwork.subnet.self_link

  min_master_version = local.defaultVersion

  lifecycle {
    ignore_changes = [node_pool]
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = google_compute_subnetwork.subnet.secondary_ip_range.0.range_name
    services_secondary_range_name = google_compute_subnetwork.subnet.secondary_ip_range.1.range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = "172.16.${var.subnet_prefix}0.16/28"
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  node_pool {
    name = "primary-pool"
  }
}

resource "google_container_node_pool" "primary" {
  provider = google-beta

  name     = "${var.prefix}-${var.region}-primary"
  location = var.region
  cluster  = google_container_cluster.phd_cluster.name

  node_count = var.zone_nodes
  version    = local.defaultVersion

  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  management {
    auto_repair  = true
    auto_upgrade = false
  }

  node_config {
    machine_type = var.machine_type
    disk_type    = "pd-ssd"
    disk_size_gb = 50
    image_type   = "COS"
    preemptible  = var.preemptible_nodes

    oauth_scopes = local.oauth_scopes

    tags = [
      "phd-app",
      "${var.prefix}-${var.region}"
    ]
    labels = {
      cluster = "${var.prefix}-${var.region}"
    }
    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  lifecycle {
    ignore_changes = [
      node_count
    ]
  }
}


