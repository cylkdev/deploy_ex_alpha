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

  public_subnet_ids       = module.vpc_instance.public_subnet_ids
  private_subnet_ids      = module.vpc_instance.private_subnet_ids

  # Allows SSH and TLS traffic.
  security_group_ids = [
    module.vpc_instance.aws_security_group_allow_ssh.id,
    module.vpc_instance.aws_security_group_allow_tls.id
  ]

  # The EC2 instance will be replaced if any of the configuration
  # values specified below is changed. This ensures instances can
  # be destroyed if any of the resources are changed.
  instance_replacement_triggered_by = [
    # SECURITY GROUP SSH
    module.vpc_instance.aws_security_group_allow_ssh.id,

    # SECURITY GROUP TLS
    module.vpc_instance.aws_security_group_allow_tls.id,

    # SECURITY GROUP INGRESS SSH
    format("%s_%s", "allow_ssh_ipv4_cidr_ipv4", module.vpc_instance.vpc_security_group_ingress_rule_allow_ssh_ipv4_cidr_ipv4),
    format("%s_%s", "allow_ssh_ipv4_ip_protocol", module.vpc_instance.vpc_security_group_ingress_rule_allow_ssh_ipv4_ip_protocol),

    # SECURITY GROUP INGRESS IPV4
    format("%s_%s", "allow_tls_ipv4_from_port", module.vpc_instance.vpc_security_group_ingress_rule_allow_tls_ipv4_from_port),
    format("%s_%s", "allow_tls_ipv4_ip_protocol", module.vpc_instance.vpc_security_group_ingress_rule_allow_tls_ipv4_ip_protocol),
    format("%s_%s", "allow_tls_ipv4_to_port", module.vpc_instance.vpc_security_group_ingress_rule_allow_tls_ipv4_to_port),

    # SECURITY GROUP EGRESS IPV4
    format("%s_%s", "allow_all_traffic_ipv4_cidr_ipv4", module.vpc_instance.vpc_security_group_egress_rule_allow_all_traffic_ipv4_cidr_ipv4),
    format("%s_%s", "allow_all_traffic_ipv4_ip_protocol", module.vpc_instance.vpc_security_group_egress_rule_allow_all_traffic_ipv4_ip_protocol)
  ]

  resource_group                       = var.resource_group
  instance_name                        = each.value.instance_name
  instance_ami_id                      = try(each.value.instance_ami_id, null)
  instance_type                        = try(each.value.instance_type, null)

  create_key_pair                      = try(each.value.create_key_pair, null)
  key_pair_key_name                    = try(each.value.key_pair_key_name, null)
            
  desired_instance_count               = try(each.value.desired_instance_count, null)
  enable_user_data                     = try(each.value.enable_user_data, null)
  user_data                            = try(each.value.user_data, null)

  placement_group_strategy             = try(each.value.placement_group_strategy, null)
  enable_auto_scaling                  = try(each.value.enable_auto_scaling, null)
  maximum_instance_count               = try(each.value.maximum_instance_count, null)
  minimum_instance_count               = try(each.value.minimum_instance_count, null)
  
  enable_ebs                           = try(each.value.enable_ebs, null)
  instance_ebs_size                    = try(each.value.instance_ebs_size, null)

  associate_public_ip_address          = try(each.value.associate_public_ip_address, null)
  enable_eip                           = try(each.value.enable_eip, null)
  enable_resource_name_dns_a_record    = try(each.value.enable_resource_name_dns_a_record, null)

  enable_elb                           = try(each.value.enable_elb, null)
  elb_port                             = try(each.value.elb_port, null)
  elb_instance_port                    = try(each.value.elb_instance_port, null)

  enable_sqs                           = try(each.value.enable_sqs, null)
  sqs_delay_seconds                    = try(each.value.sqs_delay_seconds, null)
  max_message_size                     = try(each.value.max_message_size, null)
  message_retention_seconds            = try(each.value.message_retention_seconds, null)
  receive_wait_time_seconds            = try(each.value.receive_wait_time_seconds, null)
}
