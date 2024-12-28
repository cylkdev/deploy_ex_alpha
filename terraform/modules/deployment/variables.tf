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

variable "availability_zone_names" {
  type = list(string)
  default = null
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

variable "cidr_block" {
  type = string
  nullable = false
  default = "10.16.0.0/16"
}

variable "cidrsubnet_newbits" {
  type = number
  nullable = false
  default = 4
}

variable "cidrsubnet_netnum" {
  type = number
  nullable = false
  default = 4
}

variable "subnet_count" {
  type = number
  nullable = false
  default = 2
}

variable "subnet_cidrsubnet_newbits" {
  type = number
  nullable = false
  default = 8
}

variable "enable_dns_support" {
  type = bool
  default = true
}

variable "enable_dns_hostnames" {
  type = bool
  default = true
}

variable "enable_elb" {
  type = bool
  nullable = false
  default = true
}

variable "elb_listener_port" {
  type = number
  default = 443
}

variable "elb_target_group_port" {
  type = number
  default = 443
}

variable "attach_target_group" {
  type        = bool
  nullable    = false
  default     = false
}

variable "ec2_instances" {
  type = map(object({
    instance_group           = string
    placement_group_strategy = optional(string)

    create_key_pair          = optional(bool)
    key_pair_name            = optional(string)

    enable_auto_scaling      = optional(bool)
    desired_count            = optional(number)
    minimum_instance_count   = optional(number)
    maximum_instance_count   = optional(number)

    enable_ebs               = optional(bool)
    ebs_volume_size          = optional(number)

    enable_sqs               = optional(bool)
  }))

  nullable = false
}
