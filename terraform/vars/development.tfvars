environment = "development"
region = "us-west-1"
stack = {
    olympus = {
      vpc_name = "Olympus"
      vpc_cidr = "10.0.0.0/16"
      networks = {
        zeus = {
          replicas = ["a"]
          subnet_count = 2
          instances = {
            sentry = {
              name = "Sentry"
              key_pair_name = "kurt-deploy-key"
              enable_ebs = true
              enable_user_data = true
            }
          }
        }
      }
    }
}