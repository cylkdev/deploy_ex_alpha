module "aws_deploy" {
  source = "./modules/aws-deploy"

  for_each = var.deployments

  environment     = var.environment
  region          = each.value.region
  inventory_group = each.value.inventory_group
  vpc_name        = each.value.vpc_name

  enable_elb      = try(var.enable_elb, null)
  
  ec2_instances   = try(each.value.ec2_instances, null)
}