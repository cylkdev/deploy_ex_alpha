output "vpc_instance" {
  value = aws_vpc.vpc_instance
}

output "public_internet_gateway" {
  value = aws_internet_gateway.public_internet_gateway
}

output "security_group_allow_ssh" {
  value = aws_security_group.allow_ssh
}

output "security_group_allow_tls" {
  value = aws_security_group.allow_tls
}

output "availability_zones" {
  value = data.aws_availability_zones.available
}