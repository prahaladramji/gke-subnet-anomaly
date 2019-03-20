provider "google" {
  version = "~> 2.0.0"
}

provider "google-beta" {
  version = "~> 2.0.0"
}

data "google_container_engine_versions" "region" {
  zone    = "${data.google_compute_zones.available.names[0]}"
  project = "${var.project}"
}

data "google_compute_zones" "available" {
  project = "${var.project}"
  region  = "${var.region}"
}

resource "random_shuffle" "available_zones" {
  input        = ["${data.google_compute_zones.available.names}"]
  result_count = "${var.number_of_zones}"
}

data "google_compute_network" "gke_network" {
  name    = "${var.network}"
  project = "${local.network_project_id}"
}

data "google_compute_subnetwork" "gke_subnetwork" {
  name    = "${var.subnetwork}"
  region  = "${var.region}"
  project = "${local.network_project_id}"
}

locals {
  kubernetes_version = "${var.kubernetes_version != "latest" ? var.kubernetes_version : data.google_container_engine_versions.region.latest_node_version}"
  network_project_id = "${var.network_project_id != "" ? var.network_project_id : var.project}"

  cluster_type = "regional"

  cluster_type_output_master_auth = {
    regional = "${concat(google_container_cluster.primary.*.master_auth, list())}"
  }

  cluster_type_output_endpoint = {
    regional = "${element(concat(google_container_cluster.primary.*.endpoint, list("")), 0)}"
  }

  cluster_master_auth_list_layer1 = "${local.cluster_type_output_master_auth[local.cluster_type]}"
  cluster_master_auth_list_layer2 = "${local.cluster_master_auth_list_layer1[0]}"
  cluster_master_auth_map         = "${local.cluster_master_auth_list_layer2[0]}"

  cluster_endpoint       = "${local.cluster_type_output_endpoint[local.cluster_type]}"
  cluster_ca_certificate = "${lookup(local.cluster_master_auth_map, "cluster_ca_certificate")}"
}
