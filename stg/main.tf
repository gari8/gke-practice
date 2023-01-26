terraform {
  required_version = ">=1.3.7"
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.50.0"
    }
  }
#  backend "gcs" {
#    bucket = "stately-lodge-375906-tfstate"
#    prefix = "state"
#  }
}

provider "google" {
  region  = "asia-northeast1"
}


module "database" {
  source = "../modules/database"
  private_network_id = module.network.private_network_id
  private_vpc_connection = module.network.private_vpc_connection
  project = var.project
  region = var.region
}

module "network" {
  source = "../modules/network"
  project = var.project
  region = var.region
  authorized_source_ranges = var.authorized_source_ranges
}

module "gke" {
  source = "../modules/gke"
  private_network_id = module.network.private_network_id
  project = var.project
  region = var.region
  subnetwork_web_id = module.network.subnetwork_web_id
}

output "cloud_sql_connection_name" {
  value = module.database.cloud_sql_connection_name
}

output "cloud_sql_instance_name" {
  value = module.database.cloud_sql_instance_name
}