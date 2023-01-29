variable "region" {}
variable "project" {}
variable "cluster_name" {}
variable "namespace" {}
variable "service_name" {}
variable "service_image" {}
variable "port" {}
variable "target_port" {}
variable "healthcheck_path" {}
variable "db_host" {}
variable "db_name" {
  default = "app"
}
variable "db_user" {
  default = "app"
}