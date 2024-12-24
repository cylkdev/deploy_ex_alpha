module "availability_zone_instance" {
  source = "./modules/availability-zone-instance"

  region                    = var.region
  availability_zone_count   = var.availability_zone_count
  enable_availability_zones = try(var.enable_availability_zones, null)
  all_availability_zones    = try(var.all_availability_zones, null)
  exclude_names             = try(var.exclude_names, null)
  exclude_zone_ids          = try(var.exclude_zone_ids, null)
}

module "vpc_instance" {
  source = "./modules/vpc-instance"

  environment               = var.environment
  region                    = var.region
  vpc_name                  = var.vpc_name
  
  availability_zone_names   = length(coalesce(var.availability_zone_names, [])) > 0 ? var.availability_zone_names : module.availability_zone_instance.availability_zone_names

  cidr_block                = var.cidr_block
  cidrsubnet_newbits        = try(var.cidrsubnet_newbits, null)
  cidrsubnet_netnum         = try(var.cidrsubnet_netnum, null)
 
  subnet_count              = try(var.subnet_count, null)
  subnet_cidrsubnet_newbits = var.subnet_cidrsubnet_newbits

  enable_dns_support        = var.enable_dns_support
  enable_dns_hostnames      = var.enable_dns_hostnames
}

module "ec2_instance" {
  source = "./modules/aws-instance"

  for_each = var.ec2_instances

  environment             = var.environment
  region                  = var.region
  vpc_id                  = module.vpc_instance.aws_vpc_main.id

  # Use the specified available zone names if set otherwise
  # the availability zones names exported by the
  # `availability-zone-instance` module.
  availability_zone_names = length(coalesce(var.availability_zone_names, [])) > 0 ? var.availability_zone_names : module.availability_zone_instance.availability_zone_names

  available_public_subnets  = module.vpc_instance.available_public_subnets
  available_private_subnets = module.vpc_instance.available_private_subnets

  # Allows SSH and TLS traffic.
  vpc_security_group_ids = [
    module.vpc_instance.aws_security_group_allow_ssh.id,
    module.vpc_instance.aws_security_group_allow_tls.id
  ]

  # The EC2 instance will be replaced if any of the given values change.
  # This can be used to ensure that dependent resources are destroyed
  # before trying to destroy the instance.
  replace_triggered_by = [
    # Tracks the SSH security group id.
    module.vpc_instance.aws_security_group_allow_ssh.id,

    # Tracks the HTTP traffic security group id.
    module.vpc_instance.aws_security_group_allow_tls.id,

    # Tracks SSH ingress configuration.
    format("%s_%s", "allow_ssh_ipv4_cidr_ipv4", module.vpc_instance.vpc_security_group_ingress_rule_allow_ssh_ipv4_cidr_ipv4),
    format("%s_%s", "allow_ssh_ipv4_ip_protocol", module.vpc_instance.vpc_security_group_ingress_rule_allow_ssh_ipv4_ip_protocol),

    # Tracks IPv4 ingress configuration.
    format("%s_%s", "allow_https_ipv4_from_port", module.vpc_instance.vpc_security_group_ingress_rule_allow_https_ipv4_from_port),
    format("%s_%s", "allow_https_ipv4_ip_protocol", module.vpc_instance.vpc_security_group_ingress_rule_allow_https_ipv4_ip_protocol),
    format("%s_%s", "allow_https_ipv4_to_port", module.vpc_instance.vpc_security_group_ingress_rule_allow_https_ipv4_to_port),

    # Tracks IPv4 egress configuration.
    format("%s_%s", "allow_all_traffic_ipv4_cidr_ipv4", module.vpc_instance.vpc_security_group_egress_rule_allow_all_traffic_ipv4_cidr_ipv4),
    format("%s_%s", "allow_all_traffic_ipv4_ip_protocol", module.vpc_instance.vpc_security_group_egress_rule_allow_all_traffic_ipv4_ip_protocol)
  ]

  # TODO: set this on the object so that this can be isolated
  deployment_group                     = var.deployment_group

  instance_group                        = each.value.instance_group
  instance_ami_id                      = try(each.value.instance_ami_id, null)
  instance_type                        = try(each.value.instance_type, null)

  create_key_pair                      = try(each.value.create_key_pair, null)
  key_pair_key_name                    = try(each.value.key_pair_key_name, null)
            
  desired_count               = try(each.value.desired_count, null)
  enable_user_data                     = try(each.value.enable_user_data, null)
  user_data                            = try(each.value.user_data, null)

  placement_group_strategy             = try(each.value.placement_group_strategy, null)
  enable_auto_scaling                  = try(each.value.enable_auto_scaling, null)
  maximum_instance_count               = try(each.value.maximum_instance_count, null)
  minimum_instance_count               = try(each.value.minimum_instance_count, null)
  
  enable_ebs                           = try(each.value.enable_ebs, null)
  ebs_volume_size                    = try(each.value.ebs_volume_size, null)

  associate_public_ip_address          = try(each.value.associate_public_ip_address, null)
  enable_eip                           = try(each.value.enable_eip, null)
  enable_resource_name_dns_a_record    = try(each.value.enable_resource_name_dns_a_record, null)

  enable_elb                           = try(each.value.enable_elb, null)
  elb_listener_port                    = try(each.value.elb_listener_port, null)
  elb_target_group_port                = try(each.value.elb_target_group_port, null)

  enable_sqs                           = try(each.value.enable_sqs, null)
  sqs_delay_seconds                    = try(each.value.sqs_delay_seconds, null)
  max_message_size                     = try(each.value.max_message_size, null)
  message_retention_seconds            = try(each.value.message_retention_seconds, null)
  sqs_receive_wait_time_seconds        = try(each.value.sqs_receive_wait_time_seconds, null)
}

# # --------------------------------
# # ANSIBLE
# # --------------------------------
# #
# # Generates an Ansible inventory with a list of hosts and groups.
# # Each group is named after the `deployment_group` (the key of the
# # ec2 instances object) and contains the ip address of the EC2
# # instances.
# #
# resource "local_file" "ansible_inventory" {
#   filename = "../${path.root}/terraform_exports/aws_instance_inventory.yaml"

#   content = yamlencode({
#     for module in module.ec2_instance : 
#       module.deployment_group => {
#         "hosts": [for instance in module.aws_ec2_instance : instance.public_ip]
#       }
#   })
  
#   file_permission = 0400
# }