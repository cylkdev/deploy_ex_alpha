# module: vpc-instance
# version: 0.1.0

locals {
  vpc_name_kebab_case = lower(
    replace(
      replace(
        replace(var.vpc_name, " ", "-"), 
        "/[^a-zA-Z0-9-]/", ""
      ), 
      "_", "-"
    )
  )
}

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
  cidr_block = cidrsubnet(var.cidr_block, var.cidrsubnet_newbits, var.cidrsubnet_netnum)

  enable_dns_support   = var.enable_dns_support
  enable_dns_hostnames = var.enable_dns_hostnames

  tags = merge({
    Environment    = var.environment
    InventoryGroup = var.inventory_group
    Name           = "${lower(replace(var.vpc_name, " ", "-"))}-${var.environment}-vpc"
    Region         = var.region
  }, var.tags)
}

### SECURITY GROUP

resource "aws_security_group" "allow_ssh" {
  name        = "${lower(replace(var.vpc_name, " ", "_"))}_allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.vpc_instance.id

  tags = merge({
    Environment    = var.environment
    InventoryGroup = var.inventory_group
    Name           = "${lower(replace(var.vpc_name, " ", "_"))}_${var.environment}_allow_ssh"
    Region         = var.region
  }, var.tags)
}

resource "aws_security_group" "allow_tls" {
  name        = "${lower(replace(var.vpc_name, " ", "_"))}_allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.vpc_instance.id

  tags = merge({
    Environment    = var.environment
    InventoryGroup = var.inventory_group
    Name           = "${lower(replace(var.vpc_name, " ", "_"))}_${var.environment}_allow_tls"
    Region         = var.region
  }, var.tags)
}

### VPC SECURITY GROUP

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_ingress_rule_ipv4" {
  count = var.enable_allow_ssh_ingress ? 1 : 0

  security_group_id = aws_security_group.allow_ssh.id
  
  # The rule has a default source of 0.0.0.0/0.
  # Rules with source of 0.0.0.0/0 or ::/0
  # allow all IP addresses to access your
  # instance. 
  cidr_ipv4         = var.allow_ssh_ingress_rule_ipv4_cidr # "0.0.0.0/0"
  from_port         = var.allow_ssh_ingress_rule_ipv4_from_port # 22
  to_port           = var.allow_ssh_ingress_rule_ipv4_to_port # 22
  ip_protocol       = var.allow_ssh_ingress_rule_ipv4_ip_protocol # "TCP"

  tags = merge({
    InventoryGroup = var.inventory_group
    Name           = "allow_ssh_ingress_rule_ipv4"
    Region         = var.region
  }, var.tags)
}

resource "aws_vpc_security_group_ingress_rule" "allow_https_ingress_rule_ipv4" {
  count = var.enable_allow_https_ingress ? 1 : 0
  
  security_group_id = aws_security_group.allow_tls.id

  # Rule 0.0.0.0/0 and ::/0 allow any ip to access the instance. 
  cidr_ipv4         = var.allow_https_ingress_rule_ipv4_cidr # "0.0.0.0/0"
  from_port         = var.allow_https_ingress_rule_ipv4_from_port # 443
  ip_protocol       = var.allow_https_ingress_rule_ipv4_ip_protocol # "TCP"
  to_port           = var.allow_https_ingress_rule_ipv4_to_port # 443

  tags = merge({
    InventoryGroup = var.inventory_group
    Name           = "allow_https_ingress_rule_ipv4"
    Region         = var.region
  }, var.tags)
}

resource "aws_vpc_security_group_egress_rule" "allow_traffic_egress_rule_ipv4" {
  count = var.enable_allow_traffic_egress ? 1 : 0

  security_group_id = aws_security_group.allow_tls.id
  cidr_ipv4         = var.allow_traffic_egress_rule_ipv4_cidr # "0.0.0.0/0"
  ip_protocol       = var.allow_traffic_egress_rule_ipv4_ip_protocol # "-1"

  tags = merge({
    InventoryGroup = var.inventory_group
    Name           = "allow_traffic_egress_rule_ipv4"
    Region         = var.region
  }, var.tags)
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

  vpc_id            = aws_vpc.vpc_instance.id
  cidr_block        = cidrsubnet(aws_vpc.vpc_instance.cidr_block, var.subnet_cidrsubnet_newbits, count.index + 1)

  availability_zone = element(data.aws_availability_zones.available.names, count.index % length(data.aws_availability_zones.available.names))

  tags = merge({
    AvailabilityZone = element(data.aws_availability_zones.available.names, count.index % length(data.aws_availability_zones.available.names))
    Environment      = var.environment
    InventoryGroup   = var.inventory_group
    Name             = format("%s-%s-%s-%s-%s", local.vpc_name_kebab_case, "private", var.environment, "sn", count.index)
    Region           = var.region
  }, var.tags)
}

resource "aws_route_table" "private_route_table" {
  count = var.subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.vpc_instance.id

  tags = merge({
    Environment = var.environment
    InventoryGroup   = var.inventory_group
    Name        = format("%s-%s-%s", local.vpc_name_kebab_case, var.environment, "private-rt")
    Region      = var.region
  }, var.tags)
}

resource "aws_route_table_association" "private_route_table_association" {
  count = var.subnet_count
  
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table[0].id
}

# ---
#
# Creates `count` amount of public subnets per availability zone.
resource "aws_subnet" "public_subnet" {
  count = var.subnet_count

  vpc_id = aws_vpc.vpc_instance.id

  # The CIDR block is offset by the length of the private subnets.
  # This allows the ip range of the public subnet to begin after
  # the private subnet range.
  cidr_block        = cidrsubnet(aws_vpc.vpc_instance.cidr_block, var.subnet_cidrsubnet_newbits, var.subnet_count + count.index + 1)
  availability_zone = element(data.aws_availability_zones.available.names, count.index % length(data.aws_availability_zones.available.names))

  tags = merge({
    AvailabilityZone = element(data.aws_availability_zones.available.names, count.index % length(data.aws_availability_zones.available.names))
    Environment      = var.environment
    InventoryGroup   = var.inventory_group
    Name             = format("%s-%s-%s-%s-%s", local.vpc_name_kebab_case, "public", var.environment, "sn", count.index)
    Region           = var.region
  }, var.tags)
}

resource "aws_internet_gateway" "public_internet_gateway" {
  count = var.subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.vpc_instance.id

  tags = merge({
    Environment    = var.environment
    InventoryGroup = var.inventory_group
    Name           = format("%s-%s-%s-%s", local.vpc_name_kebab_case, "public", var.environment, "igw")
    Region         = var.region
  }, var.tags)
}

resource "aws_route_table" "public_route_table" {
  count = var.subnet_count > 0 ? 1 : 0

  vpc_id = aws_vpc.vpc_instance.id

  # This allows instances within the public subnet to communicate with the internet.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_internet_gateway[0].id
  }

  tags = merge({
    Name           = format("%s-%s-%s", local.vpc_name_kebab_case, var.environment, "public-rt")
    Environment    = var.environment
    InventoryGroup = var.inventory_group
    Region         = var.region
  }, var.tags)
}

resource "aws_route_table_association" "public_route_table_association" {
  count = var.subnet_count
  
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table[0].id
}