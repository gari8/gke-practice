variable "region" {
  type    = string
  default = "asia-northeast1"
}

variable "project" {
  default = "gke-app-artifacts"
}

variable "cluster_name" {
  default = "private"
}

variable "gke_namespace" {
  default = "app"
}