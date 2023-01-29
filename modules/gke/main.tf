resource "google_container_cluster" "private" {
  provider = google-beta

  name     = var.cluster_name
  project  = var.project
  location = var.region

  network    = var.private_network_id
  subnetwork = var.subnetwork_web_id

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

resource "google_service_account" "custom" {
  project      = var.project
  account_id   = "cloud-sql-access"
  display_name = "Service account used to access cloud sql instance"
}

resource "google_project_iam_binding" "cloudsql_client" {
  role = "roles/cloudsql.client"
  members = [
    "serviceAccount:${google_service_account.custom.email}",
  ]
  project = var.project
}

data "google_project" "project" {
  project_id = var.project
}

data "google_client_config" "current" {}

provider "kubernetes" {
  host                   = "https://${google_container_cluster.private.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.private.master_auth.0.cluster_ca_certificate)
  token                  = data.google_client_config.current.access_token
}

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.namespace
  }
}
#
#module "api" {
#  source        = "../service"
#  project       = var.project
#  region        = var.region
#  cluster_name  = google_container_cluster.private.name
#  namespace     = var.namespace
#  service_name  = "api"
#  service_image = "${var.region}-docker.pkg.dev/${var.project}/${module.api_repo.repository_id}/api:latest"
#  port          = 80
#  target_port   = 80
#  healthcheck_path = "/*"
#  db_host = "${kubernetes_service.cloud_sql_proxy.metadata.0.name}:${kubernetes_service.cloud_sql_proxy.spec.0.port.0.port}"
#}
#
#module "admin" {
#  source           = "../service"
#  project          = var.project
#  region           = var.region
#  cluster_name     = google_container_cluster.private.name
#  namespace        = var.namespace
#  service_name     = "admin"
#  service_image    = "${var.region}-docker.pkg.dev/${var.project}/${module.admin_repo.repository_id}/admin:latest"
#  port             = 80
#  target_port      = 8080
#  healthcheck_path = "/admin/*"
#  db_host = "${kubernetes_service.cloud_sql_proxy.metadata.0.name}:${kubernetes_service.cloud_sql_proxy.spec.0.port.0.port}"
#}
#
#resource "kubernetes_ingress" "ingress" {
#  metadata {
#    name        = "${google_container_cluster.private.name}-ingress"
#    namespace   = var.namespace
#    annotations = {
#      "kubernetes.io/ingress.global-static-ip-name" = module.api.service_name
#      "kubernetes.io/ingress.class"                 = "gce"
#    }
#  }
#  spec {
#    backend {
#      service_name = module.api.service_name
#      service_port = 80
#    }
#
#    rule {
#      http {
#        path {
#          path = module.api.service_healthcheck_path
#          backend {
#            service_name = module.api.service_name
#            service_port = module.api.service_target_port
#          }
#        }
#        path {
#          path = module.admin.service_healthcheck_path
#          backend {
#            service_name = module.admin.service_name
#            service_port = module.admin.service_target_port
#          }
#        }
#      }
#    }
#  }
#}
#
