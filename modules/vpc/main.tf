provider "google" {
  version = "~> 2.0.0"
}

provider "google-beta" {
  version = "~> 2.0.0"
}

resource "google_compute_network" "network" {
  name                    = "${var.name}"
  auto_create_subnetworks = false
  description             = "${var.description}"
  routing_mode            = "GLOBAL"
  project                 = "${var.project}"
}

resource "google_compute_subnetwork" "subnetwork" {
  name    = "${var.subnet_name}"
  project = "${var.project}"
  region  = "${var.region}"
  network = "${google_compute_network.network.self_link}"

  ip_cidr_range = "${var.ip_cidr_range}"

  secondary_ip_range = [
    {
      ip_cidr_range = "${var.container_ip_range}"
      range_name    = "container-range-1"
    },
    {
      ip_cidr_range = "${var.service_ip_range}"
      range_name    = "service-range-1"
    },
  ]

  private_ip_google_access = true
  enable_flow_logs         = true
}

resource "google_compute_firewall" "firewall" {
  name        = "${var.name}-allow-internal"
  project     = "${var.project}"
  description = "Allow all traffic on the ${var.name} network"
  network     = "${google_compute_network.network.self_link}"
  priority    = "65534"

  allow {
    protocol = "tcp"

    ports = [
      "0-65535",
    ]
  }

  allow {
    protocol = "udp"

    ports = [
      "0-65535",
    ]
  }

  allow {
    protocol = "icmp"
  }

  source_ranges = [
    "${google_compute_subnetwork.subnetwork.*.ip_cidr_range}",
    "${var.container_ip_range}",
    "${var.service_ip_range}",
  ]
}
