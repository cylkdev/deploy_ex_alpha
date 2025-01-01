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

variable "cidrsubnet_newbits" {
  type = number
  nullable = false
  default = 0
}

variable "cidrsubnet_netnum" {
  type = number
  nullable = false
  default = 0
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