resource "aws_security_group" "compute_security_group" {
  name        = "compute-sg"
  description = "Security group for the compute service"
  vpc_id      = aws_vpc.compute_vpc.id

  ingress {
    description = "Allow MQTT/TLS from IoT VPC"
    from_port   = 8883
    to_port     = 8883
    protocol    = "tcp"
    cidr_blocks = [var.iot_vpc_cidr]
  }

  ingress {
    description = "Allow MQTT from IoT VPC"
    from_port   = 1883
    to_port     = 1883
    protocol    = "tcp"
    cidr_blocks = [var.iot_vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "compute-sg"
    Environment = var.environment
  }
}
