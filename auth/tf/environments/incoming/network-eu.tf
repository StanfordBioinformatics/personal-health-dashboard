locals {
  eu_name     = "phd-eu"
  eu_backends = module.eu_north_cluster.instance_groups
}

resource "google_compute_global_address" "eu_ip_address" {
  name        = "${local.eu_name}-ip-prod"
  description = "IP address for global load balancer for production access of MyPhD"
}

resource "google_compute_global_forwarding_rule" "glb_eu" {
  name = local.eu_name

  ip_protocol           = "TCP"
  ip_address            = google_compute_global_address.eu_ip_address.address
  load_balancing_scheme = "EXTERNAL"
  port_range            = join("-", [local.externalPort, local.externalPort])

  target = google_compute_target_tcp_proxy.glb_eu.self_link
}

resource "google_compute_target_tcp_proxy" "glb_eu" {
  name            = "${local.eu_name}-global-proxy"
  backend_service = google_compute_backend_service.glb_eu.self_link
  proxy_header    = "PROXY_V1"
}

resource "google_compute_backend_service" "glb_eu" {
  name          = local.eu_name
  description   = "Directs traffic to all regions running the PHD service"
  health_checks = [google_compute_health_check.glb_eu.self_link]
  port_name     = local.portName
  protocol      = "TCP"

  dynamic "backend" {
    for_each = [for b in local.eu_backends : b]
    content {
      group = backend.value
    }
  }

  log_config {
    enable = true
  }

  lifecycle {
    ignore_changes = [
      log_config
    ]
  }
}

resource "google_compute_health_check" "glb_eu" {
  name                = "check-${local.eu_name}-${local.portName}"
  check_interval_sec  = 10
  healthy_threshold   = 2
  timeout_sec         = 5
  unhealthy_threshold = 3

  tcp_health_check {
    port = local.port
  }
}

resource "google_compute_firewall" "allow-to-phd_eu" {
  name          = "allow-to-${local.eu_name}"
  network       = google_compute_network.network.self_link
  source_ranges = var.firewall_source_ranges

  target_tags = ["phd-app"]

  allow {
    ports    = [local.port]
    protocol = "tcp"
  }
}
