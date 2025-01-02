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

resource "aws_vpc" "vpc_instance" {
  cidr_block = var.cidr_block

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge({
    Environment = provider::corefunc::str_snake(var.environment)
    Group       = provider::corefunc::str_snake(var.vpc_group)
    Name        = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_name), var.environment, "vpc")
    Region      = provider::corefunc::str_snake(var.region)
    Vendor      = "Self"
    Type        = "Self Made"
  }, var.tags)
}

resource "aws_security_group" "allow_ssh" {
  name        = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.environment), "allow_ssh")
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.vpc_instance.id

  tags = merge({
    Environment  = provider::corefunc::str_snake(var.environment)
    Group        = provider::corefunc::str_snake(var.vpc_group)
    Name         = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.environment), "allow_ssh")
    Region       = provider::corefunc::str_snake(var.region)
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
    Environment  = provider::corefunc::str_snake(var.environment)
    Group        = provider::corefunc::str_snake(var.vpc_group)
    Name         = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.environment), "allow_ssh_ingress_rule_ipv4")
    Region       = provider::corefunc::str_snake(var.region)
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

# SECURITY GROUP - TLS
resource "aws_security_group" "allow_tls" {
  name        = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.environment), "allow_tls")
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc_instance.id

  tags = merge({
    Environment  = provider::corefunc::str_snake(var.environment)
    Group        = provider::corefunc::str_snake(var.vpc_group)
    Name         = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.environment), "allow_tls")
    Region       = provider::corefunc::str_snake(var.region)
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
    Environment  = provider::corefunc::str_snake(var.environment)
    Group        = provider::corefunc::str_snake(var.vpc_group)
    Name         = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.environment), "allow_https_ingress_rule_ipv4")
    Region       = provider::corefunc::str_snake(var.region)
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

resource "aws_vpc_security_group_egress_rule" "allow_traffic_egress_rule_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = merge({
    Environment  = provider::corefunc::str_snake(var.environment)
    Group        = provider::corefunc::str_snake(var.vpc_group)
    Name         = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.environment), "allow_traffic_egress_rule_ipv4")
    Region       = provider::corefunc::str_snake(var.region)
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

# A single VPC can be associated with only one Internet Gateway at a time.
resource "aws_internet_gateway" "public_internet_gateway" {
  vpc_id = aws_vpc.vpc_instance.id

  lifecycle {
    replace_triggered_by = [ aws_vpc.vpc_instance ]
  }

  tags = merge({
    Environment = provider::corefunc::str_snake(var.environment)
    Group       = provider::corefunc::str_snake(var.vpc_group)
    Name        = format("%s-%s-%s", provider::corefunc::str_kebab(var.vpc_name), var.environment, "igw")
    Region      = provider::corefunc::str_snake(var.region)
    Vendor      = "Self"
    Type        = "Self Made"
  }, var.tags)
}
