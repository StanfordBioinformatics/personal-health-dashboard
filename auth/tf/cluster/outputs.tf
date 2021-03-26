output "name" {
  value = google_container_cluster.phd_cluster.name
}

output "zones" {
  value = google_container_cluster.phd_cluster.node_locations
}

output "node_version" {
  value = google_container_cluster.phd_cluster.node_version
}

output "nodes_ready" {
  value = "${google_container_node_pool.primary.name == "" ? "" : ""}"
}

output "host" {
  value = google_container_cluster.phd_cluster.endpoint
}

output "instance_groups" {
  value = google_container_cluster.phd_cluster.instance_group_urls
}

output "client_certificate" {
  value = base64decode(google_container_cluster.phd_cluster.master_auth.0.client_certificate)
}

output "client_key" {
  value = base64decode(google_container_cluster.phd_cluster.master_auth.0.client_key)
}

output "cluster_ca_certificate" {
  value = base64decode(google_container_cluster.phd_cluster.master_auth.0.cluster_ca_certificate)
}

output "cluster_range" {
  description = "IP range containing Cluster IPs"
  value       = google_container_cluster.phd_cluster.ip_allocation_policy[0].cluster_secondary_range_name
}

output "service_range" {
  description = "IP range containing Service IPs"
  value       = google_container_cluster.phd_cluster.ip_allocation_policy[0].services_secondary_range_name
}

