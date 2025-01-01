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

variable "vpc_cidr" {
  type = string
  nullable = false
}

variable "vpc_cidr_newbits" {
  type = number
  nullable = false
  default = 4
}

variable "vpc_cidr_netnum" {
  type = number
  nullable = false
  default = 0
}

# variable "enable_dns_support" {
#   type = bool
#   nullable = false
#   default = true
# }

# variable "enable_dns_hostnames" {
#   type = bool
#   nullable = false
#   default = true
# }

variable "networks" {
  type = map(object({
    replicas = optional(list(string))
    availability_zone_names = optional(list(string))
    subnet_count = number
    cidrsubnet_newbits = number
    cidrsubnet_netnum = number
    enable_load_balancer = optional(bool)

    instances = map(object({
      name = string
      ami = optional(string)
      type = optional(string)
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
  }))
}
