module "deployment" {
  source = "./modules/deployment"

  for_each = var.deployments

  environment     = var.environment
  inventory_group = each.value.inventory_group
  vpc_name        = each.value.vpc_name

  enable_load_balancer                = try(var.enable_load_balancer, null)
  
  instances = try(each.value.instances, null)
}