data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "pulsar_vpc" {
  cidr_block           = var.pulsar_vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "pulsar-vpc"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "pulsar_igw" {
  vpc_id = aws_vpc.pulsar_vpc.id

  tags = {
    Name        = "pulsar-igw"
    Environment = var.environment
  }
}

resource "aws_subnet" "public_subnets" {
  count             = 2
  vpc_id            = aws_vpc.pulsar_vpc.id
  cidr_block        = cidrsubnet(var.pulsar_vpc_cidr, 3, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "public-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_subnet" "private_subnets" {
  count             = 2
  vpc_id            = aws_vpc.pulsar_vpc.id
  cidr_block        = cidrsubnet(var.pulsar_vpc_cidr, 3, count.index + 2)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "private-subnet-${count.index + 1}"
    Environment = var.environment
  }
}

resource "aws_eip" "mqtt_endpoint" {
  domain = "vpc"

  tags = {
    Name        = "pulsar-mqtt-eip"
    Environment = var.environment
  }
}

resource "aws_nat_gateway" "pulsar_nat" {
  allocation_id = aws_eip.mqtt_endpoint.id
  subnet_id     = aws_subnet.public_subnets[0].id

  tags = {
    Name        = "pulsar-nat"
    Environment = var.environment
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.pulsar_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pulsar_igw.id
  }

  tags = {
    Name        = "pulsar-public-rt"
    Environment = var.environment
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.pulsar_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.pulsar_nat.id
  }

  tags = {
    Name        = "pulsar-private-rt"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnets)
  subnet_id      = aws_subnet.public_subnets[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private_subnets)
  subnet_id      = aws_subnet.private_subnets[count.index].id
  route_table_id = aws_route_table.private.id
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
  name        = "pulsar-mqtt-tg"
  port        = 1883
  protocol    = "TCP"
  vpc_id      = aws_vpc.pulsar_vpc.id
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
    Name        = "pulsar-mqtt-tg"
    Environment = var.environment
  }
}

resource "aws_autoscaling_attachment" "mqtt" {
  autoscaling_group_name = aws_eks_node_group.pulsar_node_group.resources[0].autoscaling_groups[0].name
  lb_target_group_arn    = aws_lb_target_group.mqtt.arn
}

resource "aws_lb" "mqtt_nlb" {
  name               = "pulsar-mqtt-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = aws_subnet.public_subnets[*].id
  security_groups    = [aws_security_group.nlb_sg.id]

  tags = {
    Name        = "pulsar-mqtt-nlb"
    Environment = var.environment
  }
}