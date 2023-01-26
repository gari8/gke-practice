variable "region" {}
variable "project" {}
variable "subnetwork_web_id" {}
variable "private_network_id" {}

variable "gke_master_ipv4_cidr_block" {
  type    = string
  default = "172.23.0.0/28"
}