resource "aws_security_group" "pulsar_sg" {
  name        = "pulsar-security-group"
  description = "Security group for Pulsar cluster"
  vpc_id      = aws_vpc.pulsar_vpc.id

  ingress {
    from_port   = 1883 # MQTT port
    to_port     = 1883
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8883 # MQTT TLS port
    to_port     = 8883
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080 # Pulsar admin port
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.pulsar_vpc.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "pulsar-sg"
    Environment = var.environment
  }
}

resource "aws_security_group" "nlb_sg" {
  name        = "pulsar-nlb-sg"
  description = "Security group for Pulsar NLB"
  vpc_id      = aws_vpc.pulsar_vpc.id

  # Allow incoming MQTT traffic
  ingress {
    from_port   = 1883
    to_port     = 1883
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow incoming MQTT TLS traffic
  ingress {
    from_port   = 8883
    to_port     = 8883
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "pulsar-nlb-sg"
    Environment = var.environment
  }
}

resource "aws_security_group_rule" "mqtt_from_nlb" {
  type                     = "ingress"
  from_port                = 1883
  to_port                  = 1883
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nlb_sg.id
  security_group_id        = aws_security_group.pulsar_sg.id
}

resource "aws_security_group_rule" "mqtt_tls_from_nlb" {
  type                     = "ingress"
  from_port                = 8883
  to_port                  = 8883
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.nlb_sg.id
  security_group_id        = aws_security_group.pulsar_sg.id
}