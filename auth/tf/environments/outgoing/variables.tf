variable "google_creds_path" {
  description = <<EOF
File containing JSON credentials used to authenticate with Google Cloud and create a cluster.
Credentials can be downloaded at https://console.cloud.google.com/apis/credentials/serviceaccountkey.
EOF
  type        = string
}

variable "cluster_project" {
  description = "Google Cloud Platform project to deploy cluster in."
  type        = string
}

variable "prefix" {
  description = "Prefix used for GCP resources"
  type        = string
  default     = "phd"
}

variable "num_zones" {
  description = "Number of zones to deploy per region"
  type        = number
  default     = 3
}

variable "preemptible_nodes" {
  description = "A boolean that represents whether or not the underlying node VMs are preemptible"
  default     = true
}

variable "sftp_permissions" {
  description = "List of permissions for SFTP Auth"
  default     = ["list", "download"]
  type        = list(string)
}

variable "gcs_keys_bucket" {
  description = "GCS Bucket used for Keys for US"
  type        = string
}

variable "gcs_keys_bucket_eu" {
  description = "GCS Bucket used for Keys for EU"
  type        = string
}

variable "firewall_source_ranges" {
  description = "CIDR ranges to allow for the firewall"
  type        = list(string)
  default = [
    "130.211.0.0/22",
    "35.191.0.0/16",
  ]
}
