variable "environment" {
  type = string
  nullable = false
}

variable "deployments" {
  type = map(object({
    vpc_name        = string
    inventory_group = string

    instances = optional(map(object({
      name = string
      placement_group_strategy = optional(string)

      create_key_pair        = optional(bool)
      key_pair_name          = optional(string)

      enable_auto_scaling    = optional(bool)
      desired_count          = optional(number)
      minimum_instance_count = optional(number)
      maximum_instance_count = optional(number)

      enable_ebs             = optional(bool)
      ebs_volume_size        = optional(number)

      listener_port      = optional(number)
      target_group_port  = optional(number)

      enable_sqs             = optional(bool)
    })))
  }))

  nullable = false

  description = "Defines the resources to deploy."
}

variable "enable_load_balancer" {
  type        = bool
  nullable    = false
  default     = true
}