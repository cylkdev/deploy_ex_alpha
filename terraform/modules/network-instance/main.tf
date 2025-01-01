# AVAILABILITY ZONE
data "aws_availability_zones" "available" {
  state                  = "available"
  all_availability_zones = var.all_availability_zones
  exclude_names          = var.exclude_availability_zone_names
  exclude_zone_ids       = var.exclude_availability_zone_ids

  dynamic "filter" {
    for_each = { for name in var.availability_zone_names : name => name } 

    content {
      name   = "group-name"
      values = [each.value]
    }
  }

  filter {
    name   = "region-name"
    values = [var.region]
  }
  
  filter {
    name   = "zone-type"
    values = ["availability-zone"]
  }
}

# SECURITY GROUP - SSH
resource "aws_security_group" "allow_ssh" {
  name        = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "allow_ssh")
  description = "Allow SSH inbound traffic"
  vpc_id      = var.vpc_id

  tags = merge({
    Environment  = var.environment
    Region       = var.region
    Group        = provider::corefunc::str_snake(var.network_group)
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Name         = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "allow_ssh")
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ingress_rule_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  
  # Rules 0.0.0.0/0 or ::/0 allow all IP addresses to access your instance. 
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 22
  to_port     = 22
  ip_protocol = "TCP"

  tags = merge({
    Environment  = var.environment
    Region       = var.region
    Group        = provider::corefunc::str_snake(var.network_group)
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Name         = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "allow_ssh_ingress_rule_ipv4")
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

# SECURITY GROUP - TLS
resource "aws_security_group" "allow_tls" {
  name        = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "allow_tls")
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.vpc_id

  tags = merge({
    Environment  = var.environment
    Region       = var.region
    Group        = provider::corefunc::str_snake(var.network_group)
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Name         = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "allow_tls")
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ingress_rule_ipv4" {
  security_group_id = aws_security_group.allow_tls.id

  # Rules 0.0.0.0/0 or ::/0 allow all IP addresses to access your instance. 
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     =  443
  ip_protocol = "TCP"

  tags = merge({
    Environment  = var.environment
    Region       = var.region
    Group        = provider::corefunc::str_snake(var.network_group)
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Name         = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "allow_https_ingress_rule_ipv4")
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

resource "aws_vpc_security_group_egress_rule" "allow_traffic_egress_rule_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge({
    Environment  = var.environment
    Region       = var.region
    Group        = provider::corefunc::str_snake(var.network_group)
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Name         = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "allow_traffic_egress_rule_ipv4")
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

# SUBNET - PRIVATE
resource "aws_subnet" "private_subnet" {
  for_each = { for i in range(var.subnet_count) : "${var.vpc_group}-${var.network_group}-${var.environment}-${i}" => i }

  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.cidr_block, var.cidrsubnet_newbits, var.cidrsubnet_netnum + each.value)
  availability_zone = data.aws_availability_zones.available.names[each.value % length(data.aws_availability_zones.available.names)]

  tags = merge({
    AvailabilityZone = data.aws_availability_zones.available.names[each.value % length(data.aws_availability_zones.available.names)]
    Environment      = var.environment
    Group            = provider::corefunc::str_snake(var.network_group)
    NetworkGroup     = provider::corefunc::str_snake(var.network_group)
    Name             = format("%s-%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "private-sn", each.value)
    Vendor           = "Self"
    Type             = "Self Made"
  }, var.tags)
}

resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id

  tags = merge({
    Environment  = var.environment
    Group        = provider::corefunc::str_snake(var.network_group)
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Name         = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "private-rt")
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

resource "aws_route_table_association" "private_route_table_association" {
  for_each = { for i in range(var.subnet_count) : "${var.vpc_group}-${var.network_group}-${var.environment}-${i}" => i }
  
  subnet_id      = aws_subnet.private_subnet[each.key].id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_subnet" "public_subnet" {
  for_each = { for i in range(var.subnet_count) : "${var.vpc_group}-${var.network_group}-${var.environment}-${i}" => i }

  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.cidr_block, var.cidrsubnet_newbits, var.cidrsubnet_netnum + each.value + var.subnet_count)
  availability_zone = data.aws_availability_zones.available.names[each.value % length(data.aws_availability_zones.available.names)]

  tags = merge({
    AvailabilityZone = data.aws_availability_zones.available.names[each.value % length(data.aws_availability_zones.available.names)]
    Environment      = var.environment
    Region           = var.region
    Group            = provider::corefunc::str_snake(var.network_group)
    NetworkGroup     = provider::corefunc::str_snake(var.network_group)
    Name             = format("%s-%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "public-sn", each.value)
    Vendor           = "Self"
    Type             = "Self Made"
  }, var.tags)
}

data "aws_internet_gateway" "internet_gateway" {
  internet_gateway_id = var.gateway_id
}

resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  # The cidr block must be "0.0.0.0/0" to allow instances within
  # the public subnet to communicate with the internet.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.internet_gateway.id
  }

  tags = merge({
    Environment  = var.environment
    Group        = provider::corefunc::str_snake(var.vpc_group)
    Name         = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.network_group), provider::corefunc::str_kebab(var.environment), "public-rt")
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Region       = var.region
    Type         = "Self Made"
    Vendor       = "Self"
  }, var.tags)
}

resource "aws_route_table_association" "public_route_table_association" {
  for_each = { for i in range(var.subnet_count) : "${var.vpc_group}-${var.network_group}-${var.environment}-${i}" => i }
  
  subnet_id      = aws_subnet.public_subnet[each.key].id
  route_table_id = aws_route_table.public_route_table.id
}

module "ec2_iam_instance" {
  source = "../ec2-iam-instance"

  for_each = {
    for instance_group, instance in var.instances :
      "${instance_group}-${var.network_group}" => {
        instance_group = instance_group
        instance = instance
      }
  }

  environment    = var.environment
  region         = var.region
  vpc_group      = provider::corefunc::str_snake(var.vpc_group)
  network_group  = provider::corefunc::str_snake(var.network_group)

  instance_group = each.value.instance_group

  instance_name  = each.value.instance.name
}

module "ec2_instance" {
  source = "../ec2-instance"

  for_each = {
    for instance_group, instance in var.instances :
      "${instance_group}-${var.network_group}" => {
        instance_group = instance_group
        instance = instance
      }
  }

  environment   = var.environment
  region        = var.region
  vpc_group     = provider::corefunc::str_snake(var.vpc_group)
  network_group = provider::corefunc::str_snake(var.network_group)

  vpc_id = var.vpc_id
  
  vpc_security_group_ids = [
    aws_security_group.allow_ssh.id,
    aws_security_group.allow_tls.id
  ]

  availability_zones = data.aws_availability_zones.available.names

  public_subnets = [
    for subnet in aws_subnet.public_subnet : {
      availability_zone_name = subnet.availability_zone
      id = subnet.id
    }
  ]

  private_subnets = [
    for subnet in aws_subnet.private_subnet : {
      availability_zone_name = subnet.availability_zone
      id = subnet.id
    }
  ]

  instance_group              = each.value.instance_group
  name                        = each.value.instance.name
  ami                         = each.value.instance.ami
  instance_type               = each.value.instance.instance_type
  instance_profile_name       = module.ec2_iam_instance[each.key].ec2_instance_profile.name

  desired_count               = each.value.instance.desired_count
  cpu_core_count              = each.value.instance.cpu_core_count
  cpu_threads_per_core        = each.value.instance.cpu_threads_per_core

  enable_public_subnet        = each.value.instance.enable_public_subnet
  associate_public_ip_address = each.value.instance.associate_public_ip_address
  enable_eip                  = each.value.instance.enable_eip

  hostname_type                     = each.value.instance.hostname_type
  enable_resource_name_dns_a_record = each.value.instance.enable_resource_name_dns_a_record
  
  create_key_pair      = each.value.instance.create_key_pair
  key_pair_name        = each.value.instance.key_pair_name

  enable_load_balancer = each.value.instance.enable_load_balancer
  target_group_port    = each.value.instance.target_group_port
  listener_port        = each.value.instance.listener_port

  enable_ebs           = each.value.instance.enable_ebs
  ebs_volume_size      = each.value.instance.ebs_volume_size

  enable_user_data     = each.value.instance.enable_user_data
  user_data            = each.value.instance.user_data
}
