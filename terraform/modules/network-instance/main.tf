locals {
  subnets = [
    for i in range(var.subnet_count) : {
      index = i
      availability_zone = var.availability_zones[i % length(var.availability_zones)]
    }
  ]
}

locals {
  cidr_blocks = [ for i in range(var.subnet_count) : cidrsubnet(var.cidr_block, var.cidr_newbits, var.cidr_netnum + i) ]
}

module "subnet_instance" {
  source = "../subnet-instance"

  for_each = {
    for subnet in local.subnets :
      "${var.vpc_group}-${var.network_group}-${subnet.index}" => {
        index = subnet.index
        subnet_name = "${var.network_group}-${subnet.index}"
        availability_zone = subnet.availability_zone
        cidr_block = local.cidr_blocks[subnet.index]
      }
  }

  environment = var.environment
  region = var.region

  vpc_group           = var.vpc_group
  vpc_id              = var.vpc_id
  internet_gateway_id = var.internet_gateway_id

  network_group       = var.network_group
  subnet_name         = each.value.subnet_name

  availability_zone   = each.value.availability_zone
  cidr_block          = each.value.cidr_block
  cidr_newbits        = var.cidr_newbits
  cidr_netnum         = var.cidr_netnum
}

locals {
  public_subnets =  [
    for resource_id, module in module.subnet_instance : {
      availability_zone = module.availability_zone
      id = module.public_subnet.id
    }
  ]

  private_subnets =  [
    for resource_id, module in module.subnet_instance : {
      availability_zone = module.availability_zone
      id = module.private_subnet.id
    }
  ]
}

locals {
  instances = [
    for instance_group, instance in var.instances : {
      instance_group = instance_group
      instance = instance
    }
  ]
}

module "ec2_instance" {
  source = "../ec2-instance"

  for_each = {
    for i in range(length(local.instances)) :
      "${var.vpc_group}-${var.network_group}-${local.instances[i].instance_group}" => {
        index = i
        instance_group = local.instances[i].instance_group
        instance_name = "${local.instances[i].instance.name}-${i}"
        instance = local.instances[i].instance
      }
  }

  environment   = var.environment
  region        = var.region
  vpc_group     = var.vpc_group
  network_group = var.network_group

  vpc_id                 = var.vpc_id
  vpc_security_group_ids = var.vpc_security_group_ids

  availability_zones = var.availability_zones
  public_subnets     = local.public_subnets
  private_subnets    = local.private_subnets

  instance_group = each.value.instance_group
  name           = each.value.instance_name
  ami            = each.value.instance.ami
  instance_type  = each.value.instance.instance_type

  instance_profile_name = var.instance_profile_name
  iam_role_arn          = var.iam_role_arn

  cpu_core_count       = each.value.instance.cpu_core_count
  cpu_threads_per_core = each.value.instance.cpu_threads_per_core
  
  desired_count            = each.value.instance.desired_count
  placement_group_strategy = each.value.instance.placement_group_strategy
  minimum_instance_count   = each.value.instance.minimum_instance_count
  maximum_instance_count   = each.value.instance.maximum_instance_count

  enable_public_subnet        = each.value.instance.enable_public_subnet
  associate_public_ip_address = each.value.instance.associate_public_ip_address
  enable_eip                  = each.value.instance.enable_eip

  enable_load_balancer = each.value.instance.enable_load_balancer

  enable_target_group  = each.value.instance.enable_target_group
  attach_target_group  = each.value.instance.attach_target_group
  target_group_port    = each.value.instance.target_group_port

  enable_listener      = each.value.instance.enable_listener
  listener_port        = each.value.instance.listener_port

  enable_autoscaling   = each.value.instance.enable_autoscaling

  hostname_type                     = each.value.instance.hostname_type
  enable_resource_name_dns_a_record = each.value.instance.enable_resource_name_dns_a_record
  
  create_key_pair      = each.value.instance.create_key_pair
  key_pair_name        = each.value.instance.key_pair_name

  enable_ebs           = each.value.instance.enable_ebs
  ebs_volume_size      = each.value.instance.ebs_volume_size

  enable_user_data     = each.value.instance.enable_user_data
  user_data            = each.value.instance.user_data
}
