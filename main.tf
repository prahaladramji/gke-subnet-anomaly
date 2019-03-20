variable "project" {
  description = "Name of the Google project."
}

locals {
  project = "${var.project}"
  region  = "australia-southeast1"
  name    = "subnet-anomaly"
}

module "vpc" {
  source = "./modules/vpc"

  name    = "${local.name}"
  project = "${local.project}"
  region  = "${local.region}"

  subnet_name = "${local.name}-${local.region}"

  ip_cidr_range      = "172.31.0.0/23"
  service_ip_range   = "172.31.4.0/23"
  container_ip_range = "172.17.0.0/16"
}

module "gke" {
  source = "./modules/gke"

  name    = "${local.name}"
  project = "${local.project}"
  region  = "${local.region}"

  network           = "${module.vpc.vpc-name}"
  subnetwork        = "${module.vpc.subnet-name}"
  ip_range_pods     = "container-range-1"
  ip_range_services = "service-range-1"

  master_ipv4_cidr_block = "192.168.0.48/28"
  kubernetes_version     = "1.12.5-gke.5"
  node_pools             = []
}
