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

variable "inventory_group" {
  type = string
  nullable = false
}

variable "network_group" {
  type = string
  nullable = false
}

variable "instance_group" {
  type = string
  nullable = false
}

variable "instance_name" {
  type = string
  nullable = false
}