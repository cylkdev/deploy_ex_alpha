# -----------------------------------------------------------------------------
# Region Instance Module
#
# Description: Provision AWS resources in a region.
# Author: Kurt Hogarth <kurt@learn-elixir.dev>, Mika Kalathil <mika@learn-elixir.dev>
# Version: 0.1.0
# Last Updated: <LAST_UPDATED>
# -----------------------------------------------------------------------------

locals {
  inventory_group_kebab_case = lower(
    replace(
      replace(
        replace(var.inventory_group, " ", "-"), 
        "/[^a-zA-Z0-9-]/", ""
      ), 
      "_", "-"
    )
  )
  
  inventory_group_snake_case = lower(
    replace(
      replace(
        replace(var.inventory_group, " ", "_"),
        "/[^a-zA-Z0-9_]/",
        ""
      ),
      "-",
      "_"
    )
  )
}

module "vpc_instance" {
  source = "../vpc-instance"

  environment                     = var.environment
  region                          = var.region
  vpc_name                        = var.vpc_name
  inventory_group                 = var.inventory_group
  
  availability_zone_names         = try(var.availability_zone_names, null)
  availability_zone_count         = try(var.availability_zone_count, null)
  all_availability_zones          = try(var.all_availability_zones, null)
  exclude_availability_zone_names = try(var.exclude_availability_zone_names, null)
  exclude_availability_zone_ids   = try(var.exclude_availability_zone_ids, null)

  cidr_block                      = try(var.cidr_block, null)
  cidrsubnet_newbits              = try(var.cidrsubnet_newbits, null)
  cidrsubnet_netnum               = try(var.cidrsubnet_netnum, null)
 
  subnet_count                    = try(var.subnet_count, null)
  subnet_cidrsubnet_newbits       = try(var.subnet_cidrsubnet_newbits, null)

  enable_dns_support              = try(var.enable_dns_support, null)
  enable_dns_hostnames            = try(var.enable_dns_hostnames, null)
}

locals {
  vpc_public_subnets = { for subnet in module.vpc_instance.public_subnet : subnet.availability_zone => subnet... }
  vpc_private_subnets = { for subnet in module.vpc_instance.private_subnet : subnet.availability_zone => subnet... }
}

locals {
  # The state for each ec2 instance is resolved ahead of time here
  # to ensure that the subnets given to the module belong to the
  # availability zone the instance is being launched in.
  ec2_instances = merge(flatten([
    for instance_key, instance in var.ec2_instances : [
      for index in range(instance.desired_count) : {
        "${instance.instance_group}-${index}-${module.vpc_instance.availability_zones.names[index % length(module.vpc_instance.availability_zones.names)]}" = {
          instance_key = instance_key

          # The instance name must be unique and is set internally
          # so that it can be offset by the index.
          instance_name = "${instance.instance_group}-${index}"

          instance = instance
          availability_zone_name = module.vpc_instance.availability_zones.names[index % length(module.vpc_instance.availability_zones.names)]
          
          # Public Subnet
          #
          # Circular indexing is used here to fan out the instances
          # across subnets per availability zone.
          public_subnet = element(
            lookup(
              { for subnet in module.vpc_instance.public_subnet : subnet.availability_zone => subnet... },
              module.vpc_instance.availability_zones.names[index % length(module.vpc_instance.availability_zones.names)]
            ),
            index % length(lookup(
              { for subnet in module.vpc_instance.public_subnet : subnet.availability_zone => subnet... },
              module.vpc_instance.availability_zones.names[index % length(module.vpc_instance.availability_zones.names)]
            ))
          )
        
          # Select subnets matching the availability zone.
          public_subnets = lookup(
            { for subnet in module.vpc_instance.public_subnet : subnet.availability_zone => subnet... },
            module.vpc_instance.availability_zones.names[index % length(module.vpc_instance.availability_zones.names)]
          )

          # Private Subnet
          #
          # Circular indexing is used here to fan out the instances
          # across subnets per availability zone.
          private_subnet = element(
            lookup(
              { for subnet in module.vpc_instance.private_subnet : subnet.availability_zone => subnet... },
              module.vpc_instance.availability_zones.names[index % length(module.vpc_instance.availability_zones.names)]
            ),
            index % length(lookup(
              { for subnet in module.vpc_instance.private_subnet : subnet.availability_zone => subnet... },
              module.vpc_instance.availability_zones.names[index % length(module.vpc_instance.availability_zones.names)]
            ))
          )

          # Select subnets matching the availability zone.
          private_subnets = lookup(
            { for subnet in module.vpc_instance.private_subnet : subnet.availability_zone => subnet... },
            module.vpc_instance.availability_zones.names[index % length(module.vpc_instance.availability_zones.names)]
          )
        }
      }
    ]
  ])...)
}

module "ec2_instance" {
  source = "../ec2-instance"

  for_each = local.ec2_instances

  # General
  environment      = var.environment
  inventory_group  = var.inventory_group
  region           = var.region
  tags             = var.tags

  vpc_id           = module.vpc_instance.vpc_instance.id
  
  instance_group   = each.value.instance.instance_group
  instance_name    = each.value.instance_name

  # EC2
  instance_ami_id  = try(each.value.instance.instance_ami_id, null)
  instance_type    = try(each.value.instance.instance_type, null)

  enable_user_data = try(each.value.instance.enable_user_data, null)
  user_data        = try(each.value.instance.user_data, null)

  # Key Pair (SSH)
  create_key_pair  = try(each.value.instance.create_key_pair, null)
  key_pair_name    = try(each.value.instance.key_pair_name, null)
   
  # EBS
  enable_ebs       = try(each.value.instance.enable_ebs, null)
  ebs_volume_size  = try(each.value.instance.ebs_volume_size, null)

  associate_public_ip_address       = try(each.value.instance.associate_public_ip_address, null)
  enable_eip                        = try(each.value.instance.enable_eip, null)
  enable_resource_name_dns_a_record = try(each.value.instance.enable_resource_name_dns_a_record, null)
  
  # Availability Zone
  availability_zone_name = each.value.availability_zone_name

  # Subnet
  public_subnet_id       = each.value.public_subnet.id
  public_subnet_ids      = [ for subnet in each.value.public_subnets : subnet.id ]

  private_subnet_id      = each.value.private_subnet.id
  private_subnet_ids     = [ for subnet in each.value.private_subnets : subnet.id ]

  # Load Balancer
  enable_elb             = var.enable_elb != null ? var.enable_elb : try(each.value.instance.enable_elb, null)
  elb_listener_port      = try(each.value.instance.elb_listener_port, null)
  elb_target_group_port  = try(each.value.instance.elb_target_group_port, null)

  # Security Group
  vpc_security_group_ids = [
    module.vpc_instance.security_group_allow_ssh.id,
    module.vpc_instance.security_group_allow_tls.id
  ]

  # Lifecycle
  replace_triggered_by = [
    # Security Group SSH
    format("%s:%s", "security_group_allow_ssh", module.vpc_instance.security_group_allow_ssh.id),
    # ingress
    format("%s:%s", "security_group_allow_ssh.allow_ssh_ingress_rule_ipv4_cidr", module.vpc_instance.allow_ssh_ingress_rule_ipv4_cidr),
    format("%s:%s", "security_group_allow_ssh.allow_ssh_ingress_rule_ipv4_from_port", module.vpc_instance.allow_ssh_ingress_rule_ipv4_from_port),
    format("%s:%s", "security_group_allow_ssh.allow_ssh_ingress_rule_ipv4_to_port", module.vpc_instance.allow_ssh_ingress_rule_ipv4_to_port),
    format("%s:%s", "security_group_allow_ssh.allow_ssh_ingress_rule_ipv4_ip_protocol", module.vpc_instance.allow_ssh_ingress_rule_ipv4_ip_protocol),
    
    # Security Group TLS
    format("%s:%s", "security_group_allow_tls", module.vpc_instance.security_group_allow_tls.id),
    # ingress
    format("%s:%s", "security_group_allow_tls.allow_https_ingress_rule_ipv4_cidr", module.vpc_instance.allow_https_ingress_rule_ipv4_cidr),
    format("%s:%s", "security_group_allow_tls.allow_https_ingress_rule_ipv4_from_port", module.vpc_instance.allow_https_ingress_rule_ipv4_from_port),
    format("%s:%s", "security_group_allow_tls.allow_https_ingress_rule_ipv4_to_port", module.vpc_instance.allow_https_ingress_rule_ipv4_to_port),
    format("%s:%s", "security_group_allow_tls.allow_https_ingress_rule_ipv4_ip_protocol", module.vpc_instance.allow_https_ingress_rule_ipv4_ip_protocol),
    # egress
    format("%s:%s", "security_group_allow_tls.allow_traffic_egress_rule_ipv4", module.vpc_instance.allow_traffic_egress_rule_ipv4.id),
    format("%s:%s", "security_group_allow_tls.allow_traffic_egress_rule_ipv4_cidr", module.vpc_instance.allow_traffic_egress_rule_ipv4_cidr),
    format("%s:%s", "security_group_allow_tls.allow_traffic_egress_rule_ipv4_ip_protocol", module.vpc_instance.allow_traffic_egress_rule_ipv4_ip_protocol),
  ]
}