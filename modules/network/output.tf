output "private_network_id" {
  value = google_compute_network.custom.id
}

output "private_vpc_connection" {
  value = google_service_networking_connection.private_vpc_connection
}

output "subnetwork_web_id" {
  value = google_compute_subnetwork.web.id
}