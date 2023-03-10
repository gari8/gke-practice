resource "google_compute_network" "custom" {
  name                    = "custom"
  auto_create_subnetworks = "false"
  routing_mode            = "GLOBAL"
  project                 = var.project
}

resource "google_compute_subnetwork" "web" {
  name          = "web"
  project       = var.project
  ip_cidr_range = "10.10.10.0/24"
  network       = google_compute_network.custom.id
  region        = var.region

  secondary_ip_range = [
    {
      range_name    = "services"
      ip_cidr_range = "10.10.11.0/24"
    },
    {
      range_name    = "pods"
      ip_cidr_range = "10.1.0.0/20"
    }
  ]

  private_ip_google_access = true
}

resource "google_compute_subnetwork" "data" {
  name          = "data"
  ip_cidr_range = "10.20.10.0/24"
  network       = google_compute_network.custom.id
  project       = var.project
  region        = var.region

  private_ip_google_access = true
}

resource "google_compute_global_address" "private_ip_peering" {
  name          = "google-managed-services-custom"
  project       = var.project
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 24
  network       = google_compute_network.custom.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network = google_compute_network.custom.id
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [
    google_compute_global_address.private_ip_peering.name
  ]
}

resource "google_compute_firewall" "mysql" {
  name    = "allow-only-gke-cluster"
  project = var.project
  network = google_compute_network.custom.name

  allow {
    protocol = "tcp"
    ports    = ["3306"]
  }

  priority = 1000

  source_ranges = ["10.10.10.0/24"]
}

resource "google_compute_firewall" "web" {
  name    = "allow-all-networks"
  project = var.project
  network = google_compute_network.custom.name

  allow {
    protocol = "tcp"
    ports    = ["80", "8080"]
  }

  priority = 1000

  source_ranges = ["0.0.0.0/0"]
}

resource "google_compute_address" "web" {
  name    = "web"
  project = var.project
  region  = var.region
}

resource "google_compute_router" "web" {
  name    = "web"
  project = var.project
  network = google_compute_network.custom.id
}

resource "google_compute_router_nat" "web" {
  name                               = "web"
  project                            = var.project
  router                             = google_compute_router.web.name
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.web.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"
  subnetwork {
    name                    = google_compute_subnetwork.web.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
  depends_on = [google_compute_address.web]
}