output "vpc-name" {
  value = "${google_compute_network.network.name}"
}

output "subnet-name" {
  value = "${google_compute_subnetwork.subnetwork.name}"
}
