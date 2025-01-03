locals {
  cidr_blocks = [
    for i in range(var.subnet_count * 2) :
      cidrsubnet(var.cidr_block, var.cidr_newbits, var.cidr_netnum + i)
  ]
}

locals {
  private_subnets =  {
    for i in range(var.subnet_count) :
      "${var.vpc_group}-${var.network_group}-${i}" => {
        index = i
        availability_zone = var.availability_zones[i % length(var.availability_zones)]
        cidr_block = local.cidr_blocks[i]
      }
  }

  public_subnets =  {
    for i in range(var.subnet_count) :
      "${var.vpc_group}-${var.network_group}-${i}" => {
        index = i
        availability_zone = var.availability_zones[i % length(var.availability_zones)]
        cidr_block = local.cidr_blocks[var.subnet_count + i]
      }
  }
}

resource "aws_subnet" "private_subnet" {
  for_each = local.private_subnets

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge({
    Environment  = provider::corefunc::str_snake(var.environment)
    Group        = provider::corefunc::str_snake(var.vpc_group)
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Name         = format(
                    "%s-%s-%s-%s",
                    provider::corefunc::str_kebab(var.network_group),
                    each.value.availability_zone,
                    provider::corefunc::str_kebab(var.environment),
                    "private-sn"
                  )
    Region       = provider::corefunc::str_snake(var.region)
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id

  tags = merge({
    Environment  = provider::corefunc::str_snake(var.environment)
    Group        = provider::corefunc::str_snake(var.vpc_group)
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Name         = format(
                    "%s-%s-%s",
                    provider::corefunc::str_kebab(var.network_group),
                    provider::corefunc::str_kebab(var.environment),
                    "private-rt"
                  )
    Region       = provider::corefunc::str_snake(var.region)
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

resource "aws_route_table_association" "private_route_table_association" {
  for_each = local.private_subnets

  subnet_id      = aws_subnet.private_subnet[each.key].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_subnet" "public_subnet" {
  for_each = local.public_subnets

  vpc_id            = var.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = merge({
    Environment      = provider::corefunc::str_snake(var.environment)
    Group            = provider::corefunc::str_snake(var.vpc_group)
    NetworkGroup     = provider::corefunc::str_snake(var.network_group)
    Name             = format(
                        "%s-%s-%s-%s",
                        provider::corefunc::str_kebab(var.network_group),
                        each.value.availability_zone,
                        provider::corefunc::str_kebab(var.environment),
                        "public-sn"
                      )
    Region           = provider::corefunc::str_snake(var.region)
    Vendor           = "Self"
    Type             = "Self Made"
  }, var.tags)
}

resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  # The cidr block must be "0.0.0.0/0" to allow instances within
  # the public subnet to communicate with the internet.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = merge({
    Environment  = provider::corefunc::str_snake(var.environment)
    Group        = provider::corefunc::str_snake(var.vpc_group)
    Name         = format(
                    "%s-%s-%s",
                    provider::corefunc::str_kebab(var.network_group),
                    provider::corefunc::str_kebab(var.environment),
                    "public-rt"
                  )
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Region       = provider::corefunc::str_snake(var.region)
    Type         = "Self Made"
    Vendor       = "Self"
  }, var.tags)
}

resource "aws_route_table_association" "public_route_table_association" {
  for_each = local.public_subnets

  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public_route_table.id
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
      "${var.vpc_group}-${var.network_group}-${local.instances[i].instance_group}-${i}" => {
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

  vpc_id = var.vpc_id
  vpc_security_group_ids = var.vpc_security_group_ids

  availability_zones = var.availability_zones

  public_subnets = [
                    for key, subnet in aws_subnet.public_subnet : {
                      availability_zone = subnet.availability_zone
                      id = subnet.id
                    }
                  ]

  private_subnets = [
                      for key, subnet in aws_subnet.private_subnet : {
                        availability_zone = subnet.availability_zone
                        id = subnet.id
                      }
                    ]

  instance_group              = each.value.instance_group
  name                        = each.value.instance_name
  ami                         = each.value.instance.ami
  instance_type               = each.value.instance.instance_type

  instance_profile_name       = var.instance_profile_name
  iam_role_arn                = var.iam_role_arn

  cpu_core_count              = each.value.instance.cpu_core_count
  cpu_threads_per_core        = each.value.instance.cpu_threads_per_core
  
  desired_count               = each.value.instance.desired_count
  placement_group_strategy    = each.value.instance.placement_group_strategy
  minimum_instance_count      = each.value.instance.minimum_instance_count
  maximum_instance_count      = each.value.instance.maximum_instance_count

  enable_public_subnet        = each.value.instance.enable_public_subnet
  associate_public_ip_address = each.value.instance.associate_public_ip_address
  enable_eip                  = each.value.instance.enable_eip

  enable_load_balancer        = each.value.instance.enable_load_balancer

  enable_target_group         = each.value.instance.enable_target_group
  attach_target_group         = each.value.instance.attach_target_group
  target_group_port           = each.value.instance.target_group_port

  enable_listener             = each.value.instance.enable_listener
  listener_port               = each.value.instance.listener_port

  enable_autoscaling          = each.value.instance.enable_autoscaling

  hostname_type                     = each.value.instance.hostname_type
  enable_resource_name_dns_a_record = each.value.instance.enable_resource_name_dns_a_record
  
  create_key_pair      = each.value.instance.create_key_pair
  key_pair_name        = each.value.instance.key_pair_name

  enable_ebs           = each.value.instance.enable_ebs
  ebs_volume_size      = each.value.instance.ebs_volume_size

  enable_user_data     = each.value.instance.enable_user_data
  user_data            = each.value.instance.user_data
}
