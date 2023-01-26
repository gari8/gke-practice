resource "google_container_cluster" "private" {
  provider                 = google-beta

  name                     = "private"
  project = var.project
  location                 = var.region

  network                  = var.private_network_id
  subnetwork               = var.subnetwork_web_id

  private_cluster_config {
    enable_private_endpoint = false
    enable_private_nodes    = true
    master_ipv4_cidr_block  = var.gke_master_ipv4_cidr_block
  }

  maintenance_policy {
    recurring_window {
      start_time = "2021-06-18T00:00:00Z"
      end_time   = "2050-01-01T04:00:00Z"
      recurrence = "FREQ=WEEKLY"
    }
  }

  # Enable Autopilot for this cluster
  enable_autopilot = true

  # Configuration of cluster IP allocation for VPC-native clusters
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  # Configuration options for the Release channel feature, which provide more control over automatic upgrades of your GKE clusters.
  release_channel {
    channel = "REGULAR"
  }
}

resource "google_service_account" "web" {
  project = var.project
  account_id   = "cloud-sql-access"
  display_name = "Service account used to access cloud sql instance"
}

resource "google_project_iam_binding" "cloudsql_client" {
  role    = "roles/cloudsql.client"
  members = [
    "serviceAccount:cloud-sql-access@${data.google_project.project.project_id}.iam.gserviceaccount.com",
  ]
  project = var.project
}

data "google_project" "project" {
  project_id = var.project
}