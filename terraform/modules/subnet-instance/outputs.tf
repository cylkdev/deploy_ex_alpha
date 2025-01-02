output "environment" {
  value = var.environment
}

output "region" {
  value = var.region
}

output "tags" {
  value = var.tags
}

output "vpc_group" {
  value = var.vpc_group
}

output "vpc_id" {
  value = var.vpc_id
}

output "network_group" {
  value = var.network_group
}

output "cidr_block" {
  value = var.cidr_block
}

output "availability_zone" {
  value = var.availability_zone
}

output "internet_gateway_id" {
  value = var.internet_gateway_id
}

output "private_subnet" {
  value = aws_subnet.private_subnet
}

output "private_route_table" {
  value = aws_route_table.private_route_table
}

output "private_route_table_association" {
  value = aws_route_table_association.private_route_table_association
}

output "public_subnet" {
  value = aws_subnet.public_subnet
}

output "public_route_table" {
  value = aws_route_table.public_route_table
}

output "public_route_table_association" {
  value = aws_route_table_association.public_route_table_association
}