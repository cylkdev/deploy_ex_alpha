environment = "development"

deployments = {
  requis_us_west_1 = {
    region = "us-west-1"
    inventory_group = "requis_backend"
    vpc_name = "Requis Backend"
    tags = {}

    subnet_count = 2

    ec2_instances = {
      sentry = {
        instance_group            = "Sentry"
        placement_group_strategy  = "cluster"
        key_pair_name             = "kurt-deploy-key"

        enable_auto_scaling       = true
        desired_count             = 1
        minimum_instance_count    = 1
        maximum_instance_count    = 1

        enable_ebs                = true
        enable_user_data          = true

        ebs_volume_size = 20
      }
    }
  }
}