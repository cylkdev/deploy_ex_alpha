resource "aws_vpc" "vpc_instance" {
  cidr_block = cidrsubnet(var.cidr_block, var.cidrsubnet_newbits, var.cidrsubnet_netnum)

  enable_dns_support = var.enable_dns_support
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
