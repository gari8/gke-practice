provider "google" {
  region  = var.region
  project = var.project
}

terraform {
  required_version = ">=1.3.7"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.50.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.17.0"
    }
  }
  backend "gcs" {
  }
}

module "database" {
  source                 = "../modules/database"
  private_network_id     = module.network.private_network_id
  private_vpc_connection = module.network.private_vpc_connection
  project                = var.project
  region                 = var.region
}

module "network" {
  source  = "../modules/network"
  project = var.project
  region  = var.region
}

module "gke" {
  source                         = "../modules/gke"
  private_network_id             = module.network.private_network_id
  project                        = var.project
  region                         = var.region
  subnetwork_web_id              = module.network.subnetwork_web_id
  cluster_name                   = var.cluster_name
  namespace                      = var.gke_namespace
  cloud_sql_instance_name        = module.database.cloud_sql_instance_name
}

module "api_repo" {
  source                = "../modules/registry"
  project               = var.project
  region                = var.region
  repository_id         = "${var.project}-api-repo"
  service_account_email = google_service_account.circleci_account.email
}

module "admin_repo" {
  source                = "../modules/registry"
  project               = var.project
  region                = var.region
  repository_id         = "${var.project}-admin-repo"
  service_account_email = google_service_account.circleci_account.email
}

resource "google_service_account" "circleci_account" {
  account_id   = "circleci"
  display_name = "CircleCI"
}

resource "google_compute_global_address" "ip_address" {
  name = var.gke_namespace
}

#output "cloud_sql_connection_name" {
#  value = module.database.cloud_sql_connection_name
#}
#
#output "cloud_sql_instance_name" {
#  value = module.database.cloud_sql_instance_name
#}