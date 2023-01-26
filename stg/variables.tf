variable "region" {
  type = string
  default = "asia-northeast1"
}

variable "project" {
  default = "stately-lodge-375906"
}

variable "authorized_source_ranges" {
  type        = list(string)
  description = "Addresses or CIDR blocks which are allowed to connect to GKE API Server."
}