resource "aws_subnet" "private_subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.cidr_block, var.cidr_newbits, var.cidr_netnum)
  availability_zone = var.availability_zone

  tags = merge({
    Environment      = provider::corefunc::str_snake(var.environment)
    Group            = provider::corefunc::str_snake(var.vpc_group)
    NetworkGroup     = provider::corefunc::str_snake(var.network_group)
    Name             = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.subnet_name), provider::corefunc::str_kebab(var.environment), "private-sn")
    Region           = provider::corefunc::str_snake(var.region)
    Vendor           = "Self"
    Type             = "Self Made"
  }, var.tags)
}

resource "aws_route_table" "private_route_table" {
  vpc_id = var.vpc_id

  tags = merge({
    Environment  = provider::corefunc::str_snake(var.environment)
    Group        = provider::corefunc::str_snake(var.vpc_group)
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Name         = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.subnet_name), provider::corefunc::str_kebab(var.environment), "private-rt")
    Region       = provider::corefunc::str_snake(var.region)
    Vendor       = "Self"
    Type         = "Self Made"
  }, var.tags)
}

resource "aws_route_table_association" "private_route_table_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = var.vpc_id
  cidr_block        = cidrsubnet(var.cidr_block, var.cidr_newbits, var.cidr_netnum + 1)
  availability_zone = var.availability_zone

  tags = merge({
    Environment      = provider::corefunc::str_snake(var.environment)
    Group            = provider::corefunc::str_snake(var.vpc_group)
    NetworkGroup     = provider::corefunc::str_snake(var.network_group)
    Name             = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.subnet_name), provider::corefunc::str_kebab(var.environment), "public-sn")
    Region           = provider::corefunc::str_snake(var.region)
    Type             = "Self Made"
    Vendor           = "Self"
  }, var.tags)
}

resource "aws_route_table" "public_route_table" {
  vpc_id = var.vpc_id

  # The cidr block must be "0.0.0.0/0" to allow instances within
  # the public subnet to communicate with the internet.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.internet_gateway_id
  }

  tags = merge({
    Environment  = provider::corefunc::str_snake(var.environment)
    Group        = provider::corefunc::str_snake(var.vpc_group)
    Name         = format("%s-%s-%s-%s", provider::corefunc::str_kebab(var.vpc_group), provider::corefunc::str_kebab(var.subnet_name), provider::corefunc::str_kebab(var.environment), "public-rt")
    NetworkGroup = provider::corefunc::str_snake(var.network_group)
    Region       = provider::corefunc::str_snake(var.region)
    Type         = "Self Made"
    Vendor       = "Self"
  }, var.tags)
}

resource "aws_route_table_association" "public_route_table_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}