output "vpc_instance" {
  value = aws_vpc.vpc_instance
}

output "public_internet_gateway" {
  value = aws_internet_gateway.public_internet_gateway
}