module "stack_instance" {
  source = "./modules/stack-instance"
  
  for_each = var.stack

  environment      = var.environment
  region           = var.region
  tags             = var.tags

  vpc_group        = each.key
  vpc_name         = each.value.vpc_name

  cidr_block   = each.value.cidr_block
  cidr_newbits = each.value.cidr_newbits
  cidr_netnum  = each.value.cidr_netnum

  networks = each.value.networks
}
