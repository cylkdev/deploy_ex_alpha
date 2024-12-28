variable "environment" {
  type = string
  nullable = false
}

variable "attach_target_group" {
  type        = bool
  nullable    = false
  default     = false
}

variable "deployments" {
  type = map(object({
    region          = string
    inventory_group = string
    vpc_name        = string

    ec2_instances = optional(map(object({
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

      # Load Balancer
      elb_listener_port        = optional(number)
      elb_target_group_port    = optional(number)

      # Simple Queue Service
      enable_sqs               = optional(bool)
    })))
  }))

  nullable = false
  description = "Defines the resources to deploy."
}