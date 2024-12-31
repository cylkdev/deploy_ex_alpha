variable "environment" {
  type = string
  nullable = false
  default = "development"
}

variable "region" {
  type = string
  nullable = false
  default = "us-west-1"
}

variable "tags" {
  type = map(string)
  nullable = false
  default = {}
}

variable "enable_listener" {
  type = bool
  default = null
}

variable "deploys" {
  type = map(object({
    vpc_name = string
    cidr_block = string
    cidrsubnet_netnum = optional(number)
    cidrsubnet_newbits = optional(number)

    networks = map(object({
      availability_zone_names = optional(list(string))
      subnet_count = optional(number)
      cidrsubnet_netnum = optional(number)
      cidrsubnet_newbits = optional(number)

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

        enable_load_balancer = optional(bool)
        enable_listener = optional(bool)
        target_group_port = optional(number)
        listener_port = optional(number)

        enable_ebs = optional(bool)
        ebs_volume_size = optional(number)

        enable_eip = optional(bool)
      }))
    }))
  }))

  nullable = false

  default = {
    orange_backend = {
      vpc_name        = "Orange"
      cidr_block      = "10.100.0.0/16"

      networks = {
        alpha = {
          instances = {
            sentry = {
              instance_name = "Sentry"
              key_pair_name = "kurt-deploy-key"

              enable_ebs = true
              enable_user_data = true
            }
          }
        }
      }
    }
  }
}
