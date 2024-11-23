# // GATEWAYS //

resource "aws_secretsmanager_secret" "gateway_credentials" {
  count = var.number_of_gateways
  name  = "irrigation-gateway-${format("%03d", count.index + 1)}-credentials"

  tags = {
    Environment = var.environment
    ThingName   = aws_iot_thing.gateway[count.index].name
    Type        = "gateway"
  }
}

resource "aws_secretsmanager_secret_version" "gateway_credentials" {
  count     = var.number_of_gateways
  secret_id = aws_secretsmanager_secret.gateway_credentials[count.index].id
  secret_string = jsonencode({
    certificate_pem = aws_iot_certificate.gateway_cert[count.index].certificate_pem
    private_key     = aws_iot_certificate.gateway_cert[count.index].private_key
    public_key      = aws_iot_certificate.gateway_cert[count.index].public_key
    thing_name      = aws_iot_thing.gateway[count.index].name
    certificate_arn = aws_iot_certificate.gateway_cert[count.index].arn
  })
}


// compute //

resource "aws_secretsmanager_secret" "compute_credentials" {
  name = "irrigation-compute-credentials"

  tags = {
    Environment = var.environment
    ThingName   = aws_iot_thing.compute_service.name
    Type        = "compute"
  }
}

resource "aws_secretsmanager_secret_version" "compute_credentials" {
  secret_id = aws_secretsmanager_secret.compute_credentials.id
  secret_string = jsonencode({
    certificate_pem = aws_iot_certificate.compute_cert.certificate_pem
    private_key     = aws_iot_certificate.compute_cert.private_key
    public_key      = aws_iot_certificate.compute_cert.public_key
    thing_name      = aws_iot_thing.compute_service.name
    certificate_arn = aws_iot_certificate.compute_cert.arn
  })
}

resource "aws_security_group" "iot_endpoint_sg" {
  name        = "iot-endpoint-sg"
  description = "Security group for IoT Core VPC endpoint"
  vpc_id      = aws_vpc.iot_vpc.id

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [var.compute_sg_id]
  }
}
