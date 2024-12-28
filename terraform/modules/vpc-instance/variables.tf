variable "environment" {
  type = string
  nullable = false
}

variable "region" {
  type = string
  nullable = false
}

variable "inventory_group" {
  type = string
  nullable = false
}

variable "tags" {
  type = map(string)
  nullable = false
  default = {}
}

# VPC

variable "vpc_name" {
  type = string
  nullable = false
}

# Network

variable "cidr_block" {
  type = string
  nullable = false
  default = "10.0.0.0/16"
}

variable "cidrsubnet_netnum" {
  type = number
  nullable = false
  default = 4
}

variable "cidrsubnet_newbits" {
  type = number
  nullable = false
  default = 4
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

# ---

variable "enable_allow_ssh_ingress" {
  type = bool
  nullable = false
  default = true
  description = "Allows all inbound traffic on port 22."
}

variable "allow_ssh_ingress_rule_ipv4_cidr" {
  type = string
  default = "0.0.0.0/0"
}

variable "allow_ssh_ingress_rule_ipv4_from_port" {
  type = number
  default = 22
}

variable "allow_ssh_ingress_rule_ipv4_to_port" {
  type = number
  default = 22
}

variable "allow_ssh_ingress_rule_ipv4_ip_protocol" {
  type = string
  default = "TCP"
}

# ---

variable "enable_allow_https_ingress" {
  type = bool
  nullable = false
  default = true
  description = "Allows all inbound traffic on port 443."
}

variable "allow_https_ingress_rule_ipv4_cidr" {
  type = string
  default = "0.0.0.0/0"
}

variable "allow_https_ingress_rule_ipv4_from_port" {
  type = number
  default = 443
}

variable "allow_https_ingress_rule_ipv4_to_port" {
  type = number
  default = 443
}

variable "allow_https_ingress_rule_ipv4_ip_protocol" {
  type = string
  default = "TCP"
}

# ---

variable "enable_allow_traffic_egress" {
  type = bool
  nullable = false
  default = true
  description = "Allows all outbound traffic."
}

variable "allow_traffic_egress_rule_ipv4_cidr" {
  type = string
  default = "0.0.0.0/0"
}

variable "allow_traffic_egress_rule_ipv4_ip_protocol" {
  type = string
  default = "-1"
}

# ---

variable "subnet_count" {
  description = "Number of subnets"
  type = number
  nullable = false
  default = 2
}

variable "subnet_cidrsubnet_newbits" {
  type = number
  nullable = false
  default = 8
}

# Availability Zone

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
