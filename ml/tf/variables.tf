variable "google_creds_path" {
  description = <<EOF
File containing JSON credentials used to authenticate with Google Cloud and create a cluster.
Credentials can be downloaded at https://console.cloud.google.com/apis/credentials/serviceaccountkey.
EOF
  type        = string
}

variable "project_id" {
  description = "Google Cloud Platform project to deploy cluster in."
  type        = string
}

variable "region" {
  description = "Google Cloud Platform region to deploy cluster in."
  type        = string
}

variable "network" {
  description = "Google Cloud Platform network to deploy cluster in."
  type        = string
}

variable "subnetwork" {
  description = "Google Cloud Platform subnetwork to deploy cluster in."
  type        = string
}

variable "prefix" {
  description = "Prefix used for GCP resources"
  type        = string
  default     = "cov"
}

variable "node_pools" {
  description = "Configuration for node pools"
  type        = list(any)
}

variable "node_pools_labels" {
  type        = map(map(string))
  description = "Map of maps containing node labels by node-pool name"
}

variable "cluster" {
  description = "GKE Cluster configuration"
  type        = map(any)
}

variable "namespaces" {
  default = {
    "argo-events" = {},
    "ml"          = {},
    "decrypt"     = {}
  }
}

variable "bastion_members" {
  type        = list(string)
  description = "List of users, groups, SAs who need access to the bastion host"
  default     = []
}
