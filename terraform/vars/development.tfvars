### GENERAL

environment               = "development"
region                    = "us-west-1"
project_name              = "ExampleProject"
tags                      = {}

vpc_name                  = "TestDeployEx"

### EC2

ec2_instances = {
  group_name = {
    instance_name             = "ExampleInstance"
    placement_group_strategy  = "cluster"

    create_key_pair           = true

    enable_auto_scaling       = true
    desired_instance_count    = 2
    minimum_instance_count    = 1
    maximum_instance_count    = 1

    enable_ebs                = true
    instance_ebs_size         = 20

    enable_elb                = true
    enable_sqs                = true
  }
}