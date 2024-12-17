### GENERAL

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

### VPC

variable "availability_zone_names" {
  type = list(string)
  nullable = false
  default = []
}

variable "vpc_name" {
  type = string
  nullable = false
}

variable "vpc_security_group_ingress_rule_allow_ssh_ipv4_cidr_ipv4" {
  type = string
  nullable = false
  default = "0.0.0.0/0"
}

variable "vpc_security_group_ingress_rule_allow_ssh_ipv4_ip_protocol" {
  type = string
  nullable = false
  default = "22"
}

variable "vpc_security_group_ingress_rule_allow_tls_ipv4_from_port" {
  type = number
  nullable = false
  default = 443
}

variable "vpc_security_group_ingress_rule_allow_tls_ipv4_ip_protocol" {
  type = string
  nullable = false
  default = "tcp"
}

variable "vpc_security_group_ingress_rule_allow_tls_ipv4_to_port" {
  type = number
  nullable = false
  default = 443
}

variable "vpc_security_group_egress_rule_allow_all_traffic_ipv4_cidr_ipv4" {
  type = string
  nullable = false
  default = "0.0.0.0/0"
}

variable "vpc_security_group_egress_rule_allow_all_traffic_ipv4_ip_protocol" {
  type = string
  nullable = false
  default = "-1"
}

### NETWORK ###

variable "cidr_block" {
  type = string
  nullable = false
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

variable "subnet_count" {
  description = "Number of subnets"
  type = number
  nullable = false
  default = 1
}

variable "subnet_cidrsubnet_newbits" {
  type = number
  nullable = false
  default = 8
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
