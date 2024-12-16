data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_iot_endpoint" "mqtt" {
  endpoint_type = "iot:Data-ATS"
}

resource "aws_vpc" "iot_vpc" {
  cidr_block           = var.iot_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "iot-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnets" {
  count             = 2
  vpc_id            = aws_vpc.iot_vpc.id
  cidr_block        = cidrsubnet(var.iot_vpc_cidr, 2, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnets" {
  count             = 2
  vpc_id            = aws_vpc.iot_vpc.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "iot_igw" {
  vpc_id = aws_vpc.iot_vpc.id

  tags = {
    Name        = "iot-igw"
    Environment = var.environment
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.iot_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.iot_igw.id
  }

  tags = {
    Name        = "iot-public-rt"
    Environment = var.environment
  }
}


resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_lb" "mqtt_nlb" {
  name               = "iot-mqtt-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public_subnets[*].id

  tags = {
    Name        = "iot-mqtt-nlb"
    Environment = var.environment
  }
}

resource "aws_lb_listener" "mqtt" {
  load_balancer_arn = aws_lb.mqtt_nlb.arn
  port              = 1883
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mqtt.arn
  }
}

resource "aws_lb_listener" "mqtt_tls" {
  load_balancer_arn = aws_lb.mqtt_nlb.arn
  port              = 8883
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.mqtt.arn
  }
}

resource "aws_lb_target_group" "mqtt" {
  name        = "iot-mqtt-tg"
  port        = 1883
  protocol    = "TCP"
  vpc_id      = aws_vpc.iot_vpc.id
  target_type = "instance"

  health_check {
    enabled             = true
    protocol            = "TCP"
    port                = 1883
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
  }

  tags = {
    Name        = "iot-mqtt-tg"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.iot_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  tags = {
    Name        = "s3-vpc-endpoint"
    Environment = var.environment
  }
}

# This endpoint exposes the IoT core inside the VPC only, which is then routed for the NLB
resource "aws_vpc_endpoint" "iot_core" {
  vpc_id             = aws_vpc.iot_vpc.id
  service_name       = "com.amazonaws.${var.aws_region}.iot.data"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = [aws_subnet.private_subnets[0].id]
  security_group_ids = [aws_security_group.iot_endpoint_sg.id]
  # private_dns_enabled = true
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.iot_vpc.id

  tags = {
    Name        = "private-rt"
    Environment = var.environment
  }
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  route_table_id  = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
}

# // VPC PEERING //

resource "aws_vpc_peering_connection" "iot_compute" {
  vpc_id      = aws_vpc.iot_vpc.id
  peer_vpc_id = var.compute_vpc_id
  auto_accept = true

  tags = {
    Name = "iot-compute-peering"
  }
}

resource "aws_route" "iot_to_compute" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = var.compute_vpc_cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.iot_compute.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
}
