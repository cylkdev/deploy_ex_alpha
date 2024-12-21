# deploy = {
#   # Note: The group name is mapped to the ansible inventory group name.
#   region    = "us-west-1"
#   group     = "Requis Backend"
#   vpc_name  = "Requis Backend Alpha"

#   instances = {
#     sentry = {
#       instance_name             = "Sentry"
#       placement_group_strategy  = "cluster"

#       create_key_pair           = true

#       enable_auto_scaling       = true
#       desired_instance_count    = 1
#       minimum_instance_count    = 1
#       maximum_instance_count    = 1

#       enable_ebs                = true

#       # The minimum requirements are:
#       #
#       # - 4 CPU Cores
#       # - 16 GB RAM
#       # - 20 GB Free Disk Space
#       #
#       # https://develop.sentry.dev/self-hosted/#required-minimum-system-resources
#       instance_ebs_size         = 20

#       enable_elb                = true
#       enable_sqs                = true
#     }
#   }
# }

### GENERAL

deployment_group          = "requis_backend"
environment               = "development"
region                    = "us-west-1"
vpc_name                  = "TestDeployEx"

### EC2

ec2_instances = {
  health = {
    instance_name             = "Health"
    placement_group_strategy  = "cluster"

    create_key_pair           = true

    enable_auto_scaling       = true
    desired_instance_count    = 1
    minimum_instance_count    = 1
    maximum_instance_count    = 1

    enable_ebs                = true
    instance_ebs_size         = 20

    enable_elb                = true
    enable_sqs                = true
  }
}