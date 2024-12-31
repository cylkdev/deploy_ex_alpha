module "deploy" {
  source = "./modules/deploy"
  
  for_each = var.deploys

  environment     = var.environment
  region          = var.region
  tags            = var.tags

  inventory_group = each.key
  vpc_name        = each.value.vpc_name
  cidr_block      = each.value.cidr_block

  enable_listener = var.enable_listener

  networks = each.value.networks
}