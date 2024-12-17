### GENERAL

variable "environment" {
  type = string
  nullable = false
}

variable "region" {
  type = string
  nullable = false
}

variable "resource_group" {
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
    instance_name                     = string
    instance_ami_id                   = optional(string)
    instance_type                     = optional(string)

    create_key_pair                   = optional(bool)
    key_pair_key_name                 = optional(string)

    enable_user_data                  = optional(bool)
    user_data                         = optional(string)

    desired_instance_count            = number

    enable_auto_scaling               = optional(bool)
    placement_group_strategy          = optional(string)
    maximum_instance_count            = optional(number)
    minimum_instance_count            = optional(number)

    enable_ebs                        = optional(bool)
    instance_ebs_size                 = optional(number)

    associate_public_ip_address       = optional(bool)
    enable_eip                        = optional(bool)
    enable_resource_name_dns_a_record = optional(bool)

    enable_elb                        = optional(bool)
    elb_port                          = optional(number)
    elb_instance_port                 = optional(number)

    enable_sqs                        = optional(bool)
    sqs_delay_seconds                 = optional(number)
    max_message_size                  = optional(number)
    message_retention_seconds         = optional(number)
    receive_wait_time_seconds         = optional(number)
  }))
  
  nullable = false
}
