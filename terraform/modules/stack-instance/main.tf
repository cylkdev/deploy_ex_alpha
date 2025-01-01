module "vpc_instance" {
  source = "../vpc-instance"

  environment = var.environment
  region      = var.region
  tags        = var.tags

  vpc_group   = var.vpc_group
  cidr_block  = var.vpc_cidr
  vpc_name    = var.vpc_name
}

module "network_instance" {
  source = "../network-instance"

  for_each = {
    for network_group, network in var.networks :
      "${var.vpc_group}-${network_group}" => {
        index = index(keys(var.networks), network_group)
        network_group = network_group
        network = network
      }
  }

  environment = var.environment
  region      = var.region
  tags        = var.tags

  vpc_group   = var.vpc_group
  vpc_id      = module.vpc_instance.vpc_instance.id
  vpc_name    = var.vpc_name

  gateway_id  = module.vpc_instance.public_internet_gateway.id
  
  network_group           = each.value.network_group
  availability_zone_names = each.value.network.availability_zone_names
  subnet_count            = each.value.network.subnet_count

  cidr_block         = cidrsubnet(var.vpc_cidr, var.vpc_cidr_newbits , var.vpc_cidr_netnum + each.value.index)
  cidrsubnet_netnum  = each.value.network.cidrsubnet_netnum
  cidrsubnet_newbits = each.value.network.cidrsubnet_newbits

  instances = each.value.network.instances
}