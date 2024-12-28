module "deployment" {
  source = "./modules/deployment"

  for_each = var.deployments

  environment     = var.environment
  region          = each.value.region
  inventory_group = each.value.inventory_group
  vpc_name        = each.value.vpc_name

  attach_target_group = try(var.attach_target_group, null)
  
  ec2_instances   = try(each.value.ec2_instances, null)
}