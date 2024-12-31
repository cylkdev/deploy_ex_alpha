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

variable "vpc_id" {
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
  default = 8
}

variable "cidrsubnet_netnum" {
  type = number
  nullable = false
  default = 0
}

variable "subnet_count" {
  type = number
  nullable = false
  default = 2
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

variable "instances" {
  type = map(object({
    instance_name = string
    instance_ami_id = optional(string)
    instance_type = optional(string)
    tags = optional(map(string))

    placement_group_strategy = optional(string)
    desired_count = optional(number)
    associate_public_ip_address = optional(bool)
    enable_public_subnet = optional(bool)

    hostname_type = optional(string)
    enable_resource_name_dns_a_record = optional(bool)

    cpu_core_count = optional(number)
    cpu_threads_per_core = optional(number)

    create_key_pair = optional(bool)
    key_pair_name = optional(string)

    enable_user_data = optional(bool)
    user_data = optional(string)

    # LOAD BALANCER
    enable_load_balancer = optional(bool)
    target_group_port = optional(number)
    listener_port = optional(number)

    enable_ebs = optional(bool)
    ebs_volume_size = optional(number)

    enable_eip = optional(bool)
  }))
}

variable "gateway_id" {
  type = string
  nullable = false
}