variable "host" {
  type = string
}

variable "cluster_project" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "region" {
  type = string
}

variable "client_certificate" {
  type = string
}

variable "client_key" {
  type = string
}

variable "cluster_ca_certificate" {
  type = string
}

variable "nodes_ready" {
  type    = string
  default = ""
}

variable "port_name" {
  description = "Name used to refer to PHD port"
  type        = string
}

variable "port_num" {
  description = "Port used for PHD"
  type        = number
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

variable "network" {
  description = "Network cluster is deployed into"
  type        = string
}

variable "zones" {
  description = "Network zones cluster is deployed into"
  type        = list(string)
}
