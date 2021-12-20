locals {
  port         = "30462"
  portName     = "sftp"
  externalPort = "5222"

  backends = concat(
    module.east_cluster.instance_groups,
    module.west_cluster.instance_groups,
  )

  elb_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]
}


resource "google_compute_network" "network" {
  name                    = "${var.prefix}-net"
  project                 = var.cluster_project
  auto_create_subnetworks = false
}


resource "google_compute_global_forwarding_rule" "glb" {
  name = "phd-us"

  ip_protocol           = "TCP"
  ip_address            = var.glb_address
  load_balancing_scheme = "EXTERNAL"
  port_range            = join("-", [local.externalPort, local.externalPort])

  target = google_compute_target_tcp_proxy.glb.self_link
}

resource "google_compute_target_tcp_proxy" "glb" {
  name            = "phd-us-global-proxy"
  backend_service = google_compute_backend_service.glb.self_link
  proxy_header    = "PROXY_V1"
}

resource "google_compute_backend_service" "glb" {
  name          = "phd-us"
  description   = "Directs traffic to all regions running the PHD service"
  health_checks = [google_compute_health_check.glb.self_link]
  port_name     = local.portName
  protocol      = "TCP"

  dynamic "backend" {
    for_each = [for b in local.backends : b]
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

resource "google_compute_health_check" "glb" {
  name                = "check-${local.portName}"
  check_interval_sec  = 10
  healthy_threshold   = 2
  timeout_sec         = 5
  unhealthy_threshold = 3

  tcp_health_check {
    port = local.port
  }
}

resource "google_compute_firewall" "allow-to-phd" {
  name          = "allow-to-phd"
  network       = google_compute_network.network.self_link
  source_ranges = local.elb_ranges

  target_tags = ["phd-app"]

  allow {
    ports    = [local.port]
    protocol = "tcp"
  }
}
