output "vpc_instance" {
  value = aws_vpc.vpc_instance
}

# ---

output "security_group_allow_ssh" {
  value = aws_security_group.allow_ssh
}

output "allow_ssh_ingress_rule_ipv4" {
  value = aws_vpc_security_group_ingress_rule.allow_ssh_ingress_rule_ipv4[0]
}

output "allow_ssh_ingress_rule_ipv4_cidr" {
  value = var.allow_ssh_ingress_rule_ipv4_from_port
}

output "allow_ssh_ingress_rule_ipv4_from_port" {
  value = var.allow_ssh_ingress_rule_ipv4_from_port
}

output "allow_ssh_ingress_rule_ipv4_to_port" {
  value = var.allow_ssh_ingress_rule_ipv4_to_port
}

output "allow_ssh_ingress_rule_ipv4_ip_protocol" {
  value = var.allow_ssh_ingress_rule_ipv4_ip_protocol
}

# ---

output "security_group_allow_tls" {
  value = aws_security_group.allow_tls
}

output "allow_https_ingress_rule_ipv4" {
  value = aws_vpc_security_group_ingress_rule.allow_https_ingress_rule_ipv4[0]
}

output "allow_https_ingress_rule_ipv4_cidr" {
  value = var.allow_https_ingress_rule_ipv4_cidr
}

output "allow_https_ingress_rule_ipv4_from_port" {
  value = var.allow_https_ingress_rule_ipv4_from_port
}

output "allow_https_ingress_rule_ipv4_ip_protocol" {
  value = var.allow_https_ingress_rule_ipv4_ip_protocol
}

output "allow_https_ingress_rule_ipv4_to_port" {
  value = var.allow_https_ingress_rule_ipv4_to_port
}

output "allow_traffic_egress_rule_ipv4" {
  value = aws_vpc_security_group_egress_rule.allow_traffic_egress_rule_ipv4[0]
}

output "allow_traffic_egress_rule_ipv4_cidr" {
  value = var.allow_traffic_egress_rule_ipv4_cidr
}

output "allow_traffic_egress_rule_ipv4_ip_protocol" {
  value = var.allow_traffic_egress_rule_ipv4_ip_protocol
}

# ---

output "private_subnet" {
  value = aws_subnet.private_subnet
}

output "private_route_table" {
  value = aws_route_table.private_route_table
}

output "private_route_table_association" {
  value = aws_route_table_association.private_route_table_association
}

# ---

output "public_subnet" {
  value = aws_subnet.public_subnet
}

output "public_internet_gateway" {
  value = aws_internet_gateway.public_internet_gateway
}

output "public_route_table" {
  value = aws_route_table.public_route_table
}

output "public_route_table_association" {
  value = aws_route_table_association.public_route_table_association
}

# ---

output "availability_zones_available" {
  value = data.aws_availability_zones.available[0]
}