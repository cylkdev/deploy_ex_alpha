module "stack_instance" {
  source = "./modules/stack-instance"
  
  for_each = var.stack

  environment      = var.environment
  region           = var.region
  tags             = var.tags

  vpc_group        = each.key
  vpc_name         = each.value.vpc_name
  vpc_cidr         = each.value.vpc_cidr
  vpc_cidr_newbits = each.value.vpc_cidr_newbits
  vpc_cidr_netnum  = each.value.vpc_cidr_netnum

  networks = each.value.networks
}