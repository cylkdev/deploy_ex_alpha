### VPC

output "aws_vpc_main" {
  value = aws_vpc.main
}


### SECURITY GROUP

output "aws_security_group_allow_ssh" {
  value = aws_security_group.allow_ssh
}

output "aws_security_group_allow_tls" {
  value = aws_security_group.allow_tls
}

# ingress_rule_allow_ssh_ipv4

output "aws_vpc_security_group_ingress_rule_allow_ssh_ipv4" {
  value = aws_vpc_security_group_ingress_rule.allow_ssh_ipv4
}

output "vpc_security_group_ingress_rule_allow_ssh_ipv4_cidr_ipv4" {
  value = var.vpc_security_group_ingress_rule_allow_ssh_ipv4_cidr_ipv4
}

output "vpc_security_group_ingress_rule_allow_ssh_ipv4_ip_protocol" {
  value = var.vpc_security_group_ingress_rule_allow_ssh_ipv4_ip_protocol
}

# ingress_rule_allow_https_ipv4

output "aws_vpc_security_group_ingress_rule_allow_https_ipv4" {
  value = aws_vpc_security_group_ingress_rule.allow_https_ipv4
}

output "vpc_security_group_ingress_rule_allow_https_ipv4_from_port" {
  value = var.vpc_security_group_ingress_rule_allow_https_ipv4_from_port
}

output "vpc_security_group_ingress_rule_allow_https_ipv4_ip_protocol" {
  value = var.vpc_security_group_ingress_rule_allow_https_ipv4_ip_protocol
}

output "vpc_security_group_ingress_rule_allow_https_ipv4_to_port" {
  value = var.vpc_security_group_ingress_rule_allow_https_ipv4_to_port
}

# egress_rule_allow_all_traffic_ipv4

output "aws_vpc_security_group_egress_rule_allow_all_traffic_ipv4" {
  value = aws_vpc_security_group_egress_rule.allow_all_traffic_ipv4
}

output "vpc_security_group_egress_rule_allow_all_traffic_ipv4_cidr_ipv4" {
  value = var.vpc_security_group_egress_rule_allow_all_traffic_ipv4_cidr_ipv4
}

output "vpc_security_group_egress_rule_allow_all_traffic_ipv4_ip_protocol" {
  value = var.vpc_security_group_egress_rule_allow_all_traffic_ipv4_ip_protocol
}

### SUBNET (PRIVATE)

output "aws_private_subnet" {
  value = aws_subnet.private_subnet
}

# ---
#
# Returns a map with details about each subnet.
# This output is used by the `aws-instance` module. 
output "available_private_subnets" {
  value = [
    for subnet in aws_subnet.private_subnet : 
      {
        availability_zone    = subnet.availability_zone
        availability_zone_id = subnet.availability_zone_id
        cidr_block           = subnet.cidr_block
        id                   = subnet.id
        ipv6_cidr_block      = subnet.ipv6_cidr_block
      }
  ]
}

output "aws_private_route_table" {
  value = aws_route_table.private_route_table
}

output "aws_private_route_table_association" {
  value = aws_route_table_association.private_route_table
}

### SUBNET (PUBLIC)

output "aws_subnet_public_subnet" {
  value = aws_subnet.public_subnet
}

# ---
#
# Returns a map with details about each subnet.
# This output is used by the `aws-instance` module. 
output "available_public_subnets" {
  value = [
    for subnet in aws_subnet.public_subnet : 
      {
        availability_zone    = subnet.availability_zone
        availability_zone_id = subnet.availability_zone_id
        cidr_block           = subnet.cidr_block
        id                   = subnet.id
        ipv6_cidr_block      = subnet.ipv6_cidr_block
      }
  ]
}

output "aws_public_route_internet_gateway" {
  value = aws_internet_gateway.public_internet_gateway
}

output "aws_public_route_table" {
  value = aws_route_table.public_route_table
}

output "aws_public_route_table_association" {
  value = aws_route_table_association.public_route_table
}
