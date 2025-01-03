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

variable "stack" {
  type = map(object({
    vpc_name     = string
    cidr_block   = string
    cidr_newbits = optional(number)
    cidr_netnum  = optional(number)

    networks = map(object({
      availability_zone_names = optional(list(string))
      subnet_count = number

      instances = map(object({
        name = string
        ami = optional(string)
        instance_type = optional(string)
        tags = optional(map(string))
        
        associate_public_ip_address = optional(bool)
        enable_public_subnet = optional(bool)
        enable_eip = optional(bool)

        hostname_type = optional(string)
        enable_resource_name_dns_a_record = optional(bool)

        cpu_core_count = optional(number)
        cpu_threads_per_core = optional(number)

        desired_count = optional(number)
        placement_group_strategy = optional(string)
        minimum_instance_count = optional(number)
        maximum_instance_count = optional(number)

        enable_load_balancer = optional(bool)

        enable_target_group = optional(bool)
        attach_target_group = optional(bool)
        target_group_port = optional(number)

        enable_listener = optional(bool)
        listener_port = optional(number)
        
        enable_autoscaling = optional(bool)

        create_key_pair = optional(bool)
        key_pair_name = optional(string)

        enable_user_data = optional(bool)
        user_data = optional(string)

        enable_ebs = optional(bool)
        ebs_volume_size = optional(number)
      }))
    }))
  }))

  nullable = false
}