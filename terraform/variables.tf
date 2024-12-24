# variable "deployments" {
#   type = list(object({
#     # GENERAL
#     environment = string
#     region      = string
#     group       = string
#     tags        = map()

#     # VPC
#     vpc_name = string
#     cidr_block = string
#     cidrsubnet_newbits = number
#     cidrsubnet_netnum = number

#     # AVAILABILITY ZONE
#     all_availability_zones = bool
#     availability_zone_count = optional(number)

#     availability_zone_names = optional(list(string))
#     exclude_availability_zone_names = optional(list(string))

#     availability_zone_ids = optional(list(string))
#     exclude_availability_zone_ids = optional(list(string))

#     # SUBNET
#     subnet_count = number
#     subnet_cidrsubnet_newbits = number

#     # DNS
#     enable_dns_support = bool
#     enable_dns_hostnames = bool

#     instances = map(object({
#       instance_group            = string
#       placement_group_strategy  = string

#       create_key_pair           = bool

#       enable_auto_scaling       = bool
#       desired_count             = number
#       minimum_instance_count    = number
#       maximum_instance_count    = number

#       enable_ebs                = bool
#       ebs_volume_size           = number

#       enable_elb                = bool
#       enable_sqs                = bool
#     }))
#   }))

#   default = [
#     {
#       # GENERAL
#       environment = "development"
#       region = "us-west-1"
#       group = "Learn Elixir Backend"
#       tags = {}

#       # VPC
#       vpc_name = "Learn Elixir Backend"
#       cidr_block = "10.16.0.0/16"
#       cidrsubnet_newbits = 4
#       cidrsubnet_netnum = 4

#       # AVAILABILITY ZONE
#       all_availability_zones = true
#       availability_zone_count = 2
      
#       availability_zone_names = [ "us-west-1a", "us-west-1b" ]
#       exclude_availability_zone_names = [ "us-west-1a" ]

#       availability_zone_ids = [ "us-west-1a", "us-west-1b" ]
#       exclude_availability_zone_ids = [ "us-west-1a" ]

#       # SUBNET
#       subnet_count = 4
#       subnet_cidrsubnet_newbits = 4

#       # DNS
#       enable_dns_support = true
#       enable_dns_hostnames = true

#       # EC2
#       instances = {
#         sentry = {
#           instance_group            = "Sentry"
#           placement_group_strategy  = "cluster"

#           create_key_pair           = true

#           enable_auto_scaling       = true
#           desired_count             = 1
#           minimum_instance_count    = 1
#           maximum_instance_count    = 1

#           enable_ebs                = true

#           # The minimum requirements are:
#           #
#           # - 4 CPU Cores
#           # - 16 GB RAM
#           # - 20 GB Free Disk Space
#           #
#           # https://develop.sentry.dev/self-hosted/#required-minimum-system-resources
#           ebs_volume_size         = 20

#           enable_elb                = true
#           enable_sqs                = true
#         }
#       }
#     }
#   ]
# }

### GENERAL

variable "environment" {
  type = string
  nullable = false
}

variable "region" {
  type = string
  nullable = false
}

variable "deployment_group" {
  description = "Value of the Group tag for all resources"
  type        = string
  nullable    = false
}

variable "tags" {
  type = map(string)
  default = {}
}

### AVAILABILITY ZONE

variable "enable_availability_zones" {
  type = bool
  default = true
}

variable "availability_zone_count" {
  type = number
  default = 1
}

variable "all_availability_zones" {
  type = bool
  default = true
}

variable "exclude_names" {
  type = list(string)
  default = null
}

variable "exclude_zone_ids" {
  type = list(string)
  default = null
}

### VPC

variable "availability_zone_names" {
  type = list(string)
  default = null
}

variable "vpc_name" {
  type = string
  nullable = false
}

variable "cidr_block" {
  type = string
  nullable = false
  default = "10.16.0.0/16"
}

variable "cidrsubnet_newbits" {
  type = number
  default = 4
}

variable "cidrsubnet_netnum" {
  type = number
  default = 4
}

variable "subnet_count" {
  type = number
  default = 1
}

variable "subnet_cidrsubnet_newbits" {
  type = number
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

variable "ec2_instances" {
  type = map(object({
    instance_group                     = string
    instance_ami_id                   = optional(string)
    instance_type                     = optional(string)

    create_key_pair                   = optional(bool)
    key_pair_key_name                 = optional(string)

    enable_user_data                  = optional(bool)
    user_data                         = optional(string)

    desired_count            = number

    enable_auto_scaling               = optional(bool)
    placement_group_strategy          = optional(string)
    maximum_instance_count            = optional(number)
    minimum_instance_count            = optional(number)

    enable_ebs                        = optional(bool)
    ebs_volume_size                 = optional(number)

    associate_public_ip_address       = optional(bool)
    enable_eip                        = optional(bool)
    enable_resource_name_dns_a_record = optional(bool)

    enable_elb                        = optional(bool)
    elb_listener_port                 = optional(number)
    elb_target_group_port             = optional(number)

    enable_sqs                        = optional(bool)
    sqs_delay_seconds                 = optional(number)
    max_message_size                  = optional(number)
    message_retention_seconds         = optional(number)
    sqs_receive_wait_time_seconds     = optional(number)
  }))
  
  nullable = false
}
