resource "google_container_cluster" "primary" {
  provider = "google-beta"

  name        = "${var.name}"
  description = "${var.description}"
  project     = "${var.project}"

  region           = "${var.region}"
  additional_zones = ["${sort(random_shuffle.available_zones.result)}"]

  network            = "${replace(data.google_compute_network.gke_network.self_link, "https://www.googleapis.com/compute/v1/", "")}"
  subnetwork         = "${replace((data.google_compute_subnetwork.gke_subnetwork.self_link), "https://www.googleapis.com/compute/v1/", "")}"
  min_master_version = "${local.kubernetes_version}"

  logging_service    = "logging.googleapis.com"
  monitoring_service = "monitoring.googleapis.com"

  initial_node_count                = 1
  master_authorized_networks_config = "${var.master_authorized_networks_config}"

  addons_config {
    http_load_balancing {
      disabled = false
    }

    horizontal_pod_autoscaling {
      disabled = false
    }

    kubernetes_dashboard {
      disabled = true
    }

    network_policy_config {
      disabled = false
    }

    istio_config {
      disabled = true
    }
  }

  ip_allocation_policy {
    cluster_secondary_range_name  = "${var.ip_range_pods}"
    services_secondary_range_name = "${var.ip_range_services}"
  }

  private_cluster_config {
    enable_private_endpoint = true
    enable_private_nodes    = true
    master_ipv4_cidr_block  = "${var.master_ipv4_cidr_block}"
  }

  maintenance_policy {
    "daily_maintenance_window" {
      start_time = "${var.maintenance_start_time}"
    }
  }

  master_auth {
    username = ""
    password = ""

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  network_policy {
    enabled = true
  }

  lifecycle {
    ignore_changes = ["node_pool", "initial_node_Count"]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  remove_default_node_pool = false
}

resource "google_container_node_pool" "pools" {
  count              = "${length(var.node_pools)}"
  name_prefix        = "${lookup(var.node_pools[count.index], "name_prefix", "pool")}-"
  project            = "${var.project}"
  region             = "${var.region}"
  cluster            = "${var.name}"
  initial_node_count = 1

  autoscaling {
    max_node_count = "${lookup(var.node_pools[count.index], "max_node_count", 3)}"
    min_node_count = "${lookup(var.node_pools[count.index], "min_node_count", 1)}"
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    image_type   = "${lookup(var.node_pools[count.index], "image_type", "COS")}"
    machine_type = "${lookup(var.node_pools[count.index], "machine_type", "n1-standard-1")}"
    tags         = ["gke-${var.name}", "ecg-nat-${var.region}"]
    disk_size_gb = "${lookup(var.node_pools[count.index], "disk_size_gb", 100)}"
    disk_type    = "${lookup(var.node_pools[count.index], "disk_type", "pd-ssd")}"
    preemptible  = false

    metadata {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = ["initial_node_count"]
  }

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  depends_on = ["google_container_cluster.primary"]
}

resource "null_resource" "wait_for_regional_cluster" {
  provisioner "local-exec" {
    command = "${path.module}/scripts/wait-for-cluster.sh ${var.project} ${var.name}"
  }

  provisioner "local-exec" {
    when    = "destroy"
    command = "${path.module}/scripts/wait-for-cluster.sh ${var.project} ${var.name}"
  }

  depends_on = ["google_container_cluster.primary", "google_container_node_pool.pools"]
}
