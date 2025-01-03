environment = "dev"
region = "us-west-1"

stack = {
  olympus_backend = {
    vpc_name = "Olympus"
    cidr_block = "10.0.0.0/16"
    networks = {
      blue = {
        subnet_count = 2
        instances = {
          zeus = {
            name = "Sentry"
            ami = "ami-047d7c33f6e7b4bc4"
            instance_type = "m5.large"

            cpu_core_count = 1
            cpu_threads_per_core = 2

            key_pair_name = "kurt-deploy-key"

            enable_ebs = true
            enable_user_data = true

            attach_target_group = false

            enable_autoscaling = true
          }
        }
      }
      green = {
        subnet_count = 2
        instances = {
          zeus = {
            name = "Sentry"
            ami = "ami-047d7c33f6e7b4bc4"
            instance_type = "m5.large"

            cpu_core_count = 1
            cpu_threads_per_core = 2

            key_pair_name = "kurt-deploy-key"

            enable_ebs = true
            enable_user_data = true

            attach_target_group = false

            enable_autoscaling = true
          }
        }
      }
    }
  }

  delphi_backend = {
    vpc_name = "Delphi"
    cidr_block = "11.0.0.0/16"
    networks = {
      black = {
        subnet_count = 2
        instances = {
          zeus = {
            name = "Sentry"
            ami = "ami-047d7c33f6e7b4bc4"
            instance_type = "m5.large"

            cpu_core_count = 1
            cpu_threads_per_core = 2

            key_pair_name = "kurt-deploy-key"

            enable_ebs = true
            enable_user_data = true

            attach_target_group = false

            enable_autoscaling = true
          }
        }
      }
      white = {
        subnet_count = 2
        instances = {
          zeus = {
            name = "Sentry"
            ami = "ami-047d7c33f6e7b4bc4"
            instance_type = "m5.large"

            cpu_core_count = 1
            cpu_threads_per_core = 2

            key_pair_name = "kurt-deploy-key"

            enable_ebs = true
            enable_user_data = true

            attach_target_group = false

            enable_autoscaling = true
          }
        }
      }
    }
  }
}
