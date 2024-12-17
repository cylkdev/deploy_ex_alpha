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

# ingress_rule_allow_tls_ipv4

output "aws_vpc_security_group_ingress_rule_allow_tls_ipv4" {
  value = aws_vpc_security_group_ingress_rule.allow_tls_ipv4
}

output "vpc_security_group_ingress_rule_allow_tls_ipv4_from_port" {
  value = var.vpc_security_group_ingress_rule_allow_tls_ipv4_from_port
}

output "vpc_security_group_ingress_rule_allow_tls_ipv4_ip_protocol" {
  value = var.vpc_security_group_ingress_rule_allow_tls_ipv4_ip_protocol
}

output "vpc_security_group_ingress_rule_allow_tls_ipv4_to_port" {
  value = var.vpc_security_group_ingress_rule_allow_tls_ipv4_to_port
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

output "aws_subnet_private_subnet" {
  value = aws_subnet.private_subnet
}

output "private_subnet_ids" {
  value = [ for subnet in aws_subnet.private_subnet : subnet.id ]
}

output "aws_route_table_private_route" {
  value = aws_route_table.private_route
}

output "aws_route_table_association_private_route" {
  value = aws_route_table_association.private_route
}

### SUBNET (PUBLIC)

output "aws_subnet_public_subnet" {
  value = aws_subnet.public_subnet
}

output "public_subnet_ids" {
  value = [ for subnet in aws_subnet.public_subnet : subnet.id ]
}

output "aws_internet_gateway_public_internet_gateway" {
  value = aws_internet_gateway.public_internet_gateway
}

output "aws_route_table_public_route" {
  value = aws_route_table.public_route
}

output "aws_route_table_association_public_route" {
  value = aws_route_table_association.public_route
}
