module "vpc_instance" {
  source = "../vpc-instance"

  environment = var.environment
  region      = var.region
  tags        = var.tags

  inventory_group = var.inventory_group
  cidr_block = var.cidr_block
  vpc_name = var.vpc_name
}

module "network_instance" {
  source = "../network-instance"

  for_each = var.networks

  environment = var.environment
  region      = var.region
  tags        = var.tags

  inventory_group = var.inventory_group
  vpc_id = module.vpc_instance.vpc_instance.id
  vpc_name = var.vpc_name

  gateway_id = module.vpc_instance.public_internet_gateway.id
  
  availability_zone_names = each.value.availability_zone_names
  network_group = each.key

  cidr_block = module.vpc_instance.vpc_instance.cidr_block
  cidrsubnet_netnum = each.value.cidrsubnet_netnum
  cidrsubnet_newbits = each.value.cidrsubnet_newbits

  subnet_count = each.value.subnet_count

  enable_listener = var.enable_listener
  
  instances = each.value.instances
}


# ######################################################################
# # EC2
# ######################################################################

# # Key Pair

# resource "tls_private_key" "ssh_key" {
#   count = var.create_key_pair ? 1 : 0

#   algorithm = "RSA"
#   rsa_bits = 4096
# }

# resource "aws_key_pair" "key_pair" {
#   count = var.create_key_pair ? 1 : 0

#   key_name = var.key_pair_key_name
#   public_key = tls_private_key.ssh_key[0].public_key_openssh
# }

# resource "local_file" "ssh_key" {
#   count = var.create_key_pair ? 1 : 0

#   filename = "${path.root}/${var.key_pair_key_name}"
#   content = tls_private_key.ssh_key[0].private_key_pem
#   file_permission = 0400
# }

# # IAM

# data "aws_iam_policy_document" "trust_policy_document" {
#   statement {
#     effect  = "Allow"
#     actions = [
#       # An entity with the role can use the AWS Security Token Service
#       # to get a set of temporary security credentials that can be
#       # used to access AWS resources. 
#       "sts:AssumeRole"
#     ]

#     # These services can assume this role.
#     principals {
#       type        = "Service"
#       identifiers = [
#         "autoscaling.amazonaws.com",
#         "ec2.amazonaws.com"
#       ]
#     }
#   }
# }

# # EC2

# locals {
#   availability_zones_public_subnets = { for subnet in aws_subnet.public_subnet : subnet.availability_zone => subnet... }
#   availability_zones_private_subnets = { for subnet in aws_subnet.private_subnet : subnet.availability_zone => subnet... }
# }

# locals {
#   sorted_ec2_instances = flatten([
#     for partition_index in range(var.network_partition_count) : [
#         for instance_group, instance in var.ec2_instances : [
#             for instance_index in range(instance.desired_count) : {
#                 partition_index = partition_index
#                 instance_index  = instance_index

#                 instance_group = instance_group
#                 instance       = instance
#                 availability_zone_name = data.aws_availability_zones.available.names[instance_index % length(data.aws_availability_zones.available.names)]

#                 public_subnets = slice(
#                     lookup(local.availability_zones_public_subnets, data.aws_availability_zones.available.names[instance_index % length(data.aws_availability_zones.available.names)]),
#                     max(0, (partition_index * var.subnet_count) - 1),
#                     max(0, (partition_index * var.subnet_count) - 1) + var.subnet_count
#                 )

#                 public_subnet = element(
#                     slice(
#                         lookup(local.availability_zones_public_subnets, data.aws_availability_zones.available.names[instance_index % length(data.aws_availability_zones.available.names)]),
#                         max(0, (partition_index * var.subnet_count) - 1),
#                         max(0, (partition_index * var.subnet_count) - 1) + var.subnet_count
#                     ),
#                     instance_index % var.subnet_count
#                 )

#                 private_subnets = slice(
#                     lookup(local.availability_zones_private_subnets, data.aws_availability_zones.available.names[instance_index % length(data.aws_availability_zones.available.names)]),
#                     max(0, (partition_index * var.subnet_count) - 1),
#                     max(0, (partition_index * var.subnet_count) - 1) + var.subnet_count
#                 )

#                 private_subnet = element(
#                     slice(
#                         lookup(local.availability_zones_private_subnets, data.aws_availability_zones.available.names[instance_index % length(data.aws_availability_zones.available.names)]),
#                         max(0, (partition_index * var.subnet_count) - 1),
#                         max(0, (partition_index * var.subnet_count) - 1) + var.subnet_count
#                     ),
#                     instance_index % var.subnet_count
#                 )
#             }
#         ]
#     ]
#   ])
# }

# resource "aws_iam_role" "ec2_instance_role" {
#   name = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_name), var.environment, "instance-role")
#   assume_role_policy = data.aws_iam_policy_document.trust_policy_document.json

#   tags = merge({
#     Environment    = var.environment
#     Region         = var.region
#     Group          = provider::corefunc::str_snake(var.inventory_group)
#     Name           = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_name), var.environment, "instance-role")
#     Type           = "Self Made"
#     Vendor         = "Self"
#   }, var.tags)
# }

# resource "aws_iam_instance_profile" "ec2_instance_profile" {
#   # The name attribute must always be unique. This means that even
#   # if you have different role or path values, duplicating an
#   # existing instance profile name will lead to an
#   # EntityAlreadyExists error.
#   name = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_name), var.environment, "instance-profile")
#   role = aws_iam_role.ec2_instance_role.name
# }

# data "aws_iam_policy_document" "role_policy_document" {
#   statement {
#     effect = "Allow"
#     actions = ["autoscaling:*"]
#     resources = ["*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = ["sns:*"]
#     resources = ["*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = ["sqs:*"]
#     resources = ["*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = ["s3:*"]
#     resources = ["*"]
#   }
# }

# resource "aws_iam_role_policy" "role_policy" {
#   name   = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_name), var.environment, "role_policy")
#   role   = aws_iam_role.ec2_instance_role.id
#   policy = data.aws_iam_policy_document.role_policy_document.json
# }

# module "ec2_instance" {
#     source = "../ec2-instance"

#     count = length(local.sorted_ec2_instances)

#     environment = var.environment
#     region = var.region
#     tags = merge(var.tags, local.sorted_ec2_instances[count.index].instance.tags)

#     vpc_id = aws_vpc.vpc_instance.id
#     vpc_security_group_ids = [
#         aws_security_group.allow_ssh.id,
#         aws_security_group.allow_tls.id
#     ]

#     inventory_group = var.inventory_group
#     instance_group = local.sorted_ec2_instances[count.index].instance_group
#     instance_name = local.sorted_ec2_instances[count.index].instance.name

#     availability_zone_name = local.sorted_ec2_instances[count.index].availability_zone_name
#     load_balancer_arn = aws_lb.load_balancer[local.sorted_ec2_instances[count.index].partition_index].arn

#     enable_listener     = local.sorted_ec2_instances[count.index].instance.enable_listener
#     enable_target_group = local.sorted_ec2_instances[count.index].instance.enable_target_group

#     private_subnet_id = local.sorted_ec2_instances[count.index].private_subnet.id
#     public_subnet_id = local.sorted_ec2_instances[count.index].public_subnet.id

#     replace_triggered_by = [
#         "aws_security_group:allow_ssh:${aws_security_group.allow_ssh.id}",
#         "aws_security_group:allow_tls:${aws_security_group.allow_tls.id}"
#     ]
# }
