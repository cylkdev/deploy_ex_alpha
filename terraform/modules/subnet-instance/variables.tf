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

variable "vpc_id" {
  type = string
  nullable = false
}

variable "subnet_name" {
  type = string
  nullable = false
}

variable "network_group" {
  type = string
  nullable = false
}

variable "cidr_block" {
  type = string
  nullable = false
}

variable "cidr_newbits" {
  type = number
  nullable = false
  default = 0
}

variable "cidr_netnum" {
  type = number
  nullable = false
  default = 0
}

variable "availability_zone" {
  type = string
  nullable = false
}

variable "internet_gateway_id" {
  type = string
  nullable = false
}