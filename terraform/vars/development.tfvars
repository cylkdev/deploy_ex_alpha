environment = "development"
region = "us-west-1"
stack = {
  olympus_backend = {
    vpc_name = "Olympus"
    vpc_cidr = "10.0.0.0/16"
    networks = {
      blue = {
        subnet_count = 2
        instances = {
          poncho = {
            name = "Poncho"
            instance_type = "c8g.large"

            key_pair_name = "kurt-deploy-key"

            enable_ebs = true
            enable_user_data = true

            # Do not attach the target group to the load balancer
            # by default otherwise the load balancer will wait
            # for the instance to become healthy due to the
            # health check on the target group.
            #
            # The target group should be attached manually after
            # configuring the instance.
            attach_target_group = false

            enable_autoscaling = true
          }
        }
      }

      green = {
        subnet_count = 2
        instances = {
          poncho = {
            name = "Poncho"
            instance_type = "c8g.large"

            # 2 CPUs * 2 threads per core = 4 vCPUs
            cpu_core_count = 2
            cpu_threads_per_core = 2

            key_pair_name = "kurt-deploy-key"

            enable_ebs = true
            enable_user_data = true

            # Do not attach the target group to the load balancer
            # by default otherwise the load balancer will wait
            # for the instance to become healthy due to the
            # health check on the target group.
            #
            # The target group should be attached manually after
            # configuring the instance.
            attach_target_group = false

            enable_autoscaling = true
          }
        }
      }
    }
  }
}