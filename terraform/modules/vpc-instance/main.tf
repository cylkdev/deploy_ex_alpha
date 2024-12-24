# module: vpc-instance
# version: 0.1.0

locals {
  vpc_name_kebab_case = lower(replace(var.vpc_name, " ", "-"))
  vpc_name_snake_case = lower(replace(var.vpc_name, " ", "_"))
}

### VPC

resource "aws_vpc" "main" {
  cidr_block = cidrsubnet(var.cidr_block, var.cidrsubnet_newbits, var.cidrsubnet_netnum)

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = {
    Name        = "${lower(replace(var.vpc_name, " ", "-"))}-${var.environment}-vpc"
    Environment = var.environment
    Region      = var.region
  }
}

### SECURITY GROUP

resource "aws_security_group" "allow_ssh" {
  name        = "${lower(replace(var.vpc_name, " ", "_"))}_allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${lower(replace(var.vpc_name, " ", "_"))}_${var.environment}_allow_ssh"
    Environment = var.environment
    Region      = var.region
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "${lower(replace(var.vpc_name, " ", "_"))}_allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id

  tags = {
    Name        = "${lower(replace(var.vpc_name, " ", "_"))}_${var.environment}_allow_tls"
    Environment = var.environment
    Region      = var.region
  }
}

### VPC SECURITY GROUP

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ipv4" {
  security_group_id = aws_security_group.allow_ssh.id
  
  # The rule has a default source of 0.0.0.0/0.
  # Rules with source of 0.0.0.0/0 or ::/0
  # allow all IP addresses to access your
  # instance. 
  cidr_ipv4         = var.vpc_security_group_ingress_rule_allow_ssh_ipv4_cidr_ipv4
  
  from_port         = 22
  to_port           = 22
  ip_protocol       = var.vpc_security_group_ingress_rule_allow_ssh_ipv4_ip_protocol # tcp

  tags = {
    Name   = "allow_ssh_ipv4"
    Region = var.region
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = var.vpc_security_group_ingress_rule_allow_https_ipv4_cidr
  from_port         = var.vpc_security_group_ingress_rule_allow_https_ipv4_from_port # 443
  ip_protocol       = var.vpc_security_group_ingress_rule_allow_https_ipv4_ip_protocol # "tcp"
  to_port           = var.vpc_security_group_ingress_rule_allow_https_ipv4_to_port # 443

  tags = {
    Name   = "allow_https_ipv4"
    Region = var.region
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = var.vpc_security_group_egress_rule_allow_all_traffic_ipv4_cidr_ipv4  # "0.0.0.0/0"
  ip_protocol       = var.vpc_security_group_egress_rule_allow_all_traffic_ipv4_ip_protocol # "-1" # semantically equivalent to all ports

  tags = {
    Name   = "allow_all_traffic_ipv4"
    Region = var.region
  }
}


################################################################
# SUBNET
################################################################
#
# Subnets are a part of a VPC (Virtual Private Cloud) which is
# like a large private network that spans the AWS cloud. A subnet
# is a subdivision of the VPC's ip address range and are isolated
# from each other unless explicitly connected.
#
# > The VPC is like having your own personal bakery and a subnet
# > is an individual cake.
#
# A VPC can contain many subnets provided that each subnet:
#
#   - Has a CIDR range within the CIDR range of the VPC.
#   - The CIDR range does not overlap with other subnets in the same VPC.
#
# For example:
#
# If a VPC has a CIDR range of 10.0.0.0/16, you could create subnets like:
#
#   10.0.1.0/24 (Public Subnet in Availability Zone A).
#   10.0.2.0/24 (Private Subnet in Availability Zone A).
#   10.0.3.0/24 (Private Subnet in Availability Zone B).

# ---
#
# Creates `count` amount of private subnets per availability zone.
resource "aws_subnet" "private_subnet" {
  count = var.subnet_count

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, var.subnet_cidrsubnet_newbits, count.index + 1)
  availability_zone = element(var.availability_zone_names, count.index % length(var.availability_zone_names))

  tags = {
    AvailabilityZone = element(var.availability_zone_names, count.index % length(var.availability_zone_names))
    Environment      = var.environment
    Name             = format("%s-%s-%s-%s-%s", local.vpc_name_kebab_case, "public", var.environment, "sn", count.index)
    Region           = var.region
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = format("%s-%s-%s", local.vpc_name_kebab_case, var.environment, "private-rt")
    Environment = var.environment
    Region      = var.region
  }
}

resource "aws_route_table_association" "private_route_table" {
  count = var.subnet_count
  
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# ---
#
# Creates `count` amount of public subnets per availability zone.
resource "aws_subnet" "public_subnet" {
  count = var.subnet_count

  vpc_id = aws_vpc.main.id

  # The CIDR block is offset by the length of the private subnets.
  # This allows the ip range of the public subnet to begin after
  # the private subnet range.
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, var.subnet_cidrsubnet_newbits, var.subnet_count + count.index + 1)
  availability_zone = element(var.availability_zone_names, count.index % length(var.availability_zone_names))

  tags = {
    AvailabilityZone = element(var.availability_zone_names, count.index % length(var.availability_zone_names))
    Environment      = var.environment
    Name             = format("%s-%s-%s-%s-%s", local.vpc_name_kebab_case, "public", var.environment, "sn", count.index)
    Region           = var.region
  }
}

resource "aws_internet_gateway" "public_internet_gateway" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = format("%s-%s-%s-%s", local.vpc_name_kebab_case, "public", var.environment, "igw")
    Environment = var.environment
    Region      = var.region
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.main.id

  # This allows instances within the public subnet to communicate with the internet.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_internet_gateway.id
  }

  tags = {
    Name        = format("%s-%s-%s", local.vpc_name_kebab_case, var.environment, "public-rt")
    Environment = var.environment
    Region      = var.region
  }
}

resource "aws_route_table_association" "public_route_table" {
  count = var.subnet_count
  
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}