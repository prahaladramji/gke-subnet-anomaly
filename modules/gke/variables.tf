variable "project" {
  description = "Name of the Google project."
}

variable "name" {
  description = "Name of the GKE cluster."
}

variable "description" {
  description = "The descriptiong of the cluster."
  default     = ""
}

variable "region" {
  description = "The regions of the independent host clusters."
  default     = "australia-southeast1"
}

variable "number_of_zones" {
  description = "Number of zones to distribute the nodes in."
  default     = 3
}

variable "network" {
  description = "The VPC network to host the cluster in."
}

variable "network_project_id" {
  description = "The project ID of the shared VPC's host project."
  default     = ""
}

variable "subnetwork" {
  description = "The subnetwork to host the cluster in."
}

variable "master_ipv4_cidr_block" {
  description = "The ipv4 cidr block for the private cluster"
}

variable "kubernetes_version" {
  description = "The Kubernetes version of the masters. If set to 'latest' it will pull latest available version in the selected region."
  default     = "latest"
}

variable "maintenance_start_time" {
  description = "Time window specified for daily maintenance operations in RFC3339 format"
  default     = "16:00"
}

variable "master_authorized_networks_config" {
  type = "list"

  description = <<EOF
  The desired configuration options for master authorized networks. Omit the nested cidr_blocks attribute to disallow external access (except the cluster node IPs, which GKE automatically whitelists)

  ### example format ###
  master_authorized_networks_config = [{
    cidr_blocks = [{
      cidr_block   = "10.0.0.0/8"
      display_name = "example_network"
    }],
  }]

  EOF

  default = [{
    cidr_blocks = [{
      cidr_block   = "172.16.0.0/12"
      display_name = "project-gcp-internal"
    }]
  }]
}

variable "ip_range_pods" {
  description = "The secondary ip range to use for pods"
}

variable "ip_range_services" {
  description = "The secondary ip range to use for pods"
}

variable "node_pools" {
  type        = "list"
  description = "List of maps containing node pools"

  default = [
    {
      name         = "primary-node-pool"
      machine_type = "n1-standard-2"
    },
  ]
}
