variable "region" {
  type = string
  nullable = false
}

variable "enable_availability_zones" {
  type = bool
  nullable = false
  default = true
}

variable "all_availability_zones" {
  type = bool
  nullable = false
  default = true
}

variable "exclude_names" {
  type = list(string)
}

variable "exclude_zone_ids" {
  type = list(string)
}

variable "randomize_availability_zones" {
  type = bool
  nullable = false
  default = true
}

variable "availability_zone_count" {
  type = number
  nullable = false
  default = 2
}