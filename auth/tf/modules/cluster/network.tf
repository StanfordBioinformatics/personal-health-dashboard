resource "google_compute_subnetwork" "subnet" {
  name          = "${var.prefix}-${var.region}-subnet"
  project       = var.cluster_project
  network       = var.network
  region        = var.region
  ip_cidr_range = "10.${var.subnet_prefix}0.0.0/24"

  private_ip_google_access = true

  secondary_ip_range {
    range_name    = "${var.prefix}-${var.region}-pod-range"
    ip_cidr_range = "10.${var.subnet_prefix}1.0.0/16"
  }

  secondary_ip_range {
    range_name    = "${var.prefix}-${var.region}-svc-range"
    ip_cidr_range = "10.${var.subnet_prefix}2.0.0/20"
  }
}

data "google_container_cluster" "phd_cluster" {
  name     = local.clusterName
  location = var.region
}

// Note: needs to be applied again after Node Pool setup
resource "google_compute_instance_group_named_port" "phd_port" {
  count = length(coalesce(data.google_container_cluster.phd_cluster.instance_group_urls, []))
  group = data.google_container_cluster.phd_cluster.instance_group_urls[count.index]

  port = var.port_num
  name = var.port_name
}

// Create a cloud router for use by the Cloud NAT
resource "google_compute_router" "router" {
  name    = "${var.prefix}-${var.region}-cloud-router"
  region  = var.region
  network = var.network

  bgp {
    asn = 64514
  }
}

// Create an external NAT IP
resource "google_compute_address" "nat" {
  name   = "${var.prefix}-${var.region}-nat-ip"
  region = var.region
}

// Create a NAT router so the nodes can reach DockerHub, etc
resource "google_compute_router_nat" "nat" {
  name   = "${var.prefix}-${var.region}-cloud-nat"
  router = google_compute_router.router.name
  region = var.region

  nat_ip_allocate_option = "MANUAL_ONLY"

  nat_ips = [google_compute_address.nat.self_link]

  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.subnet.self_link
    source_ip_ranges_to_nat = ["PRIMARY_IP_RANGE", "LIST_OF_SECONDARY_IP_RANGES"]

    secondary_ip_range_names = [
      google_compute_subnetwork.subnet.secondary_ip_range.0.range_name,
      google_compute_subnetwork.subnet.secondary_ip_range.1.range_name,
    ]
  }
}
