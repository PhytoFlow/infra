resource "tls_private_key" "mqtt_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "mqtt_cert" {
  private_key_pem = tls_private_key.mqtt_key.private_key_pem

  subject {
    common_name  = aws_eip.mqtt_endpoint.public_ip
    organization = "PythoFlow"
  }

  validity_period_hours = 8760
  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]

  dns_names    = [aws_eip.mqtt_endpoint.public_ip]
  ip_addresses = [aws_eip.mqtt_endpoint.public_ip]
}