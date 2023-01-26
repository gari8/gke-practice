variable "region" {}
variable "project" {}
variable "private_network_id" {}
variable "private_vpc_connection" {}

variable "mysql_location_preference" {
  type = string
  default = "asia-northeast1-b"
}

variable "mysql_machine_type" {
  type = string
  default = "db-n1-standard-2"
}

variable "mysql_database_version" {
  type = string
  default = "MYSQL_8_0"
}

variable "mysql_default_disk_size" {
  type = string
  default = "100"
}

variable "mysql_availability_type" {
  type = string
  default = "REGIONAL"
}