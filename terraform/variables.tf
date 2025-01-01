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
    vpc_name         = string
    vpc_cidr         = string
    vpc_cidr_netnum  = optional(number)
    vpc_cidr_newbits = optional(number)

    networks = map(object({
      replicas = optional(list(string))
      availability_zone_names = optional(list(string))
      subnet_count = optional(number)
      cidrsubnet_netnum = optional(number)
      cidrsubnet_newbits = optional(number)

      instances = map(object({
        name = string
        ami = optional(string)
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

        enable_load_balancer = optional(bool)
        target_group_port = optional(number)
        listener_port = optional(number)

        enable_ebs = optional(bool)
        ebs_volume_size = optional(number)

        enable_eip = optional(bool)
      }))
    }))
  }))

  nullable = false
}
