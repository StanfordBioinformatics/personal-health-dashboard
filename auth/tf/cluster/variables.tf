variable "prefix" {
  description = "Prefix used for cluster"
  type        = string
}

variable "region" {
  description = "Region cluster should be deployed in"
  type        = string
}

variable "machine_type" {
  description = "Type of GCE instance to use for Nodes"
  type        = string
  default     = "n1-standard-8"
}

variable "zone_nodes" {
  description = "Number of nodes per zone to be deployed"
  type        = string
  default     = 1
}

variable "min_nodes" {
  description = "Minimum number of nodes per zone to be deployed"
  type        = string
  default     = 1
}

variable "max_nodes" {
  description = "Maximum number of nodes per zone to be deployed"
  type        = string
  default     = 8
}

variable "network" {
  description = "Network cluster is deployed into"
  type        = string
}

variable "subnet_prefix" {
  description = "Prefix to IP ranges created for cluster"
  type        = string
  default     = ""
}

variable "port_name" {
  description = "Name used to refer to PHD port"
  type        = string
}

variable "port_num" {
  description = "Port used for PHD"
  type        = number
}

variable "num_zones" {
  description = "Number of zones within each cluster"
  type        = number
}

variable "cluster_project" {
  description = "Google Cloud Platform project to deploy cluster in."
  type        = string
}

variable "preemptible_nodes" {
  description = "A boolean that represents whether or not the underlying node VMs are preemptible"
  default     = true
}