resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "vpc-${var.environment}-${var.application}"
  }
}

resource "aws_subnet" "subnet_private_one" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_private_one_cidr_block
  availability_zone = data.aws_availability_zones.az.names[0]

  tags = {
    Name = "subnet-priv-one-${var.environment}-${var.application}"
  }
}

resource "aws_subnet" "subnet_private_two" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_private_two_cidr_block
  availability_zone = data.aws_availability_zones.az.names[1]

  tags = {
    Name = "subnet-priv-two-${var.environment}-${var.application}"
  }
}

resource "aws_subnet" "subnet_public_one" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_public_one_cidr_block
  availability_zone = data.aws_availability_zones.az.names[0]

  tags = {
    Name = "subnet-public-one-${var.environment}-${var.application}"
  }
}

resource "aws_subnet" "subnet_public_two" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.subnet_public_two_cidr_block
  availability_zone = data.aws_availability_zones.az.names[1]

  tags = {
    Name = "subnet-public-two-${var.environment}-${var.application}"
  }
}

data "aws_availability_zones" "az" {
  state = "available"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "igw-${var.environment}-${var.application}"
  }
}

resource "aws_eip" "nat_one" {
  vpc = true
}

resource "aws_eip" "nat_two" {
  vpc = true
}

resource "aws_route_table" "rt_public" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt-public-${var.environment}-${var.application}"
  }
}

resource "aws_nat_gateway" "nat_one" {
  allocation_id = aws_eip.nat_one.id
  subnet_id     = aws_subnet.subnet_public_one.id

  tags = {
    Name = "nat-one-${var.environment}-${var.application}"
  }
}

resource "aws_nat_gateway" "nat_two" {
  allocation_id = aws_eip.nat_two.id
  subnet_id     = aws_subnet.subnet_public_two.id

  tags = {
    Name = "nat-two-${var.environment}-${var.application}"
  }
}

resource "aws_route_table" "rt_private_one" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_one.id
  }

  tags = {
    Name = "rt-private-one-${var.environment}-${var.application}"
  }
}

resource "aws_route_table" "rt_private_two" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_two.id
  }

  tags = {
    Name = "rt-private-two-${var.environment}-${var.application}"
  }
}

resource "aws_route_table_association" "public_assoc_one" {
  subnet_id      = aws_subnet.subnet_public_one.id
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "public_assoc_two" {
  subnet_id      = aws_subnet.subnet_public_two.id
  route_table_id = aws_route_table.rt_public.id
}

resource "aws_route_table_association" "private_assoc_one" {
  subnet_id      = aws_subnet.subnet_private_one.id
  route_table_id = aws_route_table.rt_private_one.id
}

resource "aws_route_table_association" "private_assoc_two" {
  subnet_id      = aws_subnet.subnet_private_two.id
  route_table_id = aws_route_table.rt_private_two.id
}
