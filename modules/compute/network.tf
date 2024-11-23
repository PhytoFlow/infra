resource "aws_vpc" "compute_vpc" {
  cidr_block           = var.compute_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "compute-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "compute_public_subnets" {
  count             = 2
  vpc_id            = aws_vpc.compute_vpc.id
  cidr_block        = cidrsubnet(var.compute_vpc_cidr, 2, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "compute-public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_subnet" "compute_private_subnets" {
  count             = 2
  vpc_id            = aws_vpc.compute_vpc.id
  cidr_block        = cidrsubnet(var.compute_vpc_cidr, 2, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "compute-private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_route_table" "compute_public" {
  vpc_id = aws_vpc.compute_vpc.id

  route {
    cidr_block = "0.0.0.0/0" # Fix this later The services shouldn't be exposed Use LB instead to client access
    gateway_id = aws_internet_gateway.compute_igw.id
  }

  route {
    cidr_block                = var.iot_vpc_cidr
    vpc_peering_connection_id = var.iot_to_compute_id
  }

  tags = {
    Name        = "compute-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table" "compute_private" {
  vpc_id = aws_vpc.compute_vpc.id

  route {
    cidr_block                = var.iot_vpc_cidr
    vpc_peering_connection_id = var.iot_to_compute_id
  }

  tags = {
    Name        = "compute-private-rt"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "compute_igw" {
  vpc_id = aws_vpc.compute_vpc.id

  tags = {
    Name        = "compute-igw"
    Environment = var.environment
  }
}

data "aws_availability_zones" "available" {
  state = "available"
}