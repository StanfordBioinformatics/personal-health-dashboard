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

variable "east_region" {
  description = "Region containing East coast cluster"
  type        = string
  default     = "us-east1"
}

variable "west_region" {
  description = "Region containing West coast cluster"
  type        = string
  default     = "us-west1"
}

variable "num_zones" {
  description = "Number of zones to deploy per region"
  type        = number
  default     = 3
}

variable "glb_address" {
  description = "IP used to Globally serve PHD traffic"
  type        = string
}

variable "preemptible_nodes" {
  description = "A boolean that represents whether or not the underlying node VMs are preemptible"
  default     = true
}

variable "sftp_permissions" {
  description = "List of permissions for SFTP Auth"
  default     = ["list"]
  type        = list(string)
}

variable "gcs_keys_bucket" {
  description = "GCS Bucket used for Keys"
  type        = string
}