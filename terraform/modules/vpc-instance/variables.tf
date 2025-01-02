variable "environment" {
  type = string
  nullable = false
}

variable "region" {
  type = string
  nullable = false
}

variable "tags" {
  type = map(string)
  nullable = false
  default = {}
}

# VPC

variable "vpc_group" {
  type = string
  nullable = false
}

variable "vpc_name" {
  type = string
  nullable = false
}

variable "cidr_block" {
  type = string
  nullable = false
}

variable "enable_dns_support" {
  type = bool
  nullable = false
  default = true
}

variable "enable_dns_hostnames" {
  type = bool
  nullable = false
  default = true
}

# AVAILABILITY ZONES

variable "availability_zone_names" {
  type = list(string)
  nullable = false
  default = []
}

variable "availability_zone_count" {
  type = number
  nullable = false
  default = 2
}

variable "all_availability_zones" {
  type = bool
  nullable = false
  default = true
}

variable "exclude_availability_zone_names" {
  type = list(string)
  nullable = false
  default = []
}

variable "exclude_availability_zone_ids" {
  type = list(string)
  nullable = false
  default = []
}

# # SUBNET

# variable "subnets" {
#   type = map(object({
#     subnet_name = string
#     subnet_count = number

#     cidr_newbits = optional(number)
#     cidr_netnum = optional(number)

#     instances = map(object({
#       instance_type = optional(string)
#     }))
#   }))
# }

