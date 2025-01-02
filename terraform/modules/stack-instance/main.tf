module "vpc_instance" {
  source = "../vpc-instance"

  environment = var.environment
  region      = var.region
  tags        = var.tags

  vpc_group   = var.vpc_group
  vpc_name    = var.vpc_name

  cidr_block  = var.cidr_block
}

module "ec2_iam_instance" {
  source = "../ec2-iam-instance"

  environment = var.environment
  region      = var.region
  vpc_group   = var.vpc_group
}

locals {
 networks = [
    for network_group, network in var.networks : {
      network_group = network_group
      network = network
    }
  ]
}

locals {
  cidr_blocks = [
    for i in range(length(local.networks)) :
    cidrsubnet(var.cidr_block, var.cidr_newbits, var.cidr_netnum + i)
  ]
}

module "network_instance" {
  source = "../network-instance"

  for_each = {
    for i in range(length(local.networks)) :
      "${var.vpc_group}-${local.networks[i].network_group}-${i}" => {
        index = i
        network_group = local.networks[i].network_group
        network = local.networks[i].network
        cidr_block = local.cidr_blocks[i]
      }
  }

  environment = var.environment
  region      = var.region

  vpc_group           = var.vpc_group
  vpc_id              = module.vpc_instance.vpc_instance.id
  internet_gateway_id = module.vpc_instance.public_internet_gateway.id

  iam_role_arn          = module.ec2_iam_instance.ec2_iam_role.arn
  instance_profile_name = module.ec2_iam_instance.ec2_instance_profile.name

  cidr_block = each.value.cidr_block

  vpc_security_group_ids = [
    module.vpc_instance.security_group_allow_ssh.id,
    module.vpc_instance.security_group_allow_tls.id
  ]
  
  availability_zones = module.vpc_instance.availability_zones.names
  subnet_count = each.value.network.subnet_count

  network_group = each.value.network_group
  instances = each.value.network.instances
}