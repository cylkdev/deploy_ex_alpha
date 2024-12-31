######################################################################
# GENERAL
######################################################################

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

variable "vpc_name" {
  type = string
  nullable = false
}

variable "cidr_block" {
  type = string
  nullable = false
}

# variable "cidrsubnet_newbits" {
#   type = number
#   nullable = false
#   default = 0
# }

# variable "cidrsubnet_netnum" {
#   type = number
#   nullable = false
#   default = 0
# }

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
    availability_zone_names = optional(list(string))

    subnet_count = number
    cidrsubnet_netnum = number
    cidrsubnet_newbits = number

    enable_load_balancer = optional(bool)

    instances = map(object({
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
  }))
}

# # AVAILABILITY ZONES
# variable "availability_zone_names" {
#   type = list(string)
#   nullable = false
#   default = []
# }

# variable "availability_zone_count" {
#   type = number
#   nullable = false
#   default = 2
# }

# variable "all_availability_zones" {
#   type = bool
#   nullable = false
#   default = true
# }

# variable "exclude_availability_zone_names" {
#   type = list(string)
#   nullable = false
#   default = []
# }

# variable "exclude_availability_zone_ids" {
#   type = list(string)
#   nullable = false
#   default = []
# }

# # SUBNET
# variable "network_partition_count" {
#   type = number
#   nullable = false
#   default = 2
# }

# variable "subnet_count" {
#   type = number
#   nullable = false
#   default = 2
# }

# variable "subnet_cidrsubnet_newbits" {
#   type = number
#   nullable = false
#   default = 12
# }

# variable "enable_load_balancer" {
#   type = bool
#   nullable = false
#   default = true
# }

# ######################################################################
# # EC2
# ######################################################################

# # KEY PAIR
# variable "create_key_pair" {
#   description = "If true, a key pair is created; if false, it is not."
#   type = bool
#   nullable = false
#   default = false
# }

# variable "key_pair_key_name" {
#   type = string
#   nullable = false
#   default = "ec2-instance-private-key.pem"
# }

# variable "ec2_instances" {
#   type = map(object({
#     name = string
#     instance_ami_id  = optional(string, "ami-047d7c33f6e7b4bc4")
#     instance_type    = optional(string, "t3.micro")
#     tags             = optional(map(string), {})

#     desired_count    = optional(number, 2)
#     enable_user_data = optional(bool, false)
#     user_data        = optional(string, "")

#     public                      = optional(bool, true)
#     associate_public_ip_address = optional(bool, true)

#     cpu_core_count       = optional(number, 1)
#     cpu_threads_per_core = optional(number, 2)

#     hostname_type                     = optional(string, "resource-name")
#     enable_resource_name_dns_a_record = optional(bool, true)

#     enable_listener = optional(bool, false)
#     enable_target_group = optional(bool, true)

#     enable_ebs = optional(bool, true)
#     ebs_volume_size = optional(number, 16)

#     enable_eip = optional(bool, true)
#   }))
#   nullable = false
#   default = {}
# }