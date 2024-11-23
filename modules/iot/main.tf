# // DEVICES //

resource "aws_iot_thing_type" "sensor_gateway" {
  name = "sensor_gateway"
  properties {
    description = "ESP32 gateway"
  }
}

resource "aws_iot_thing" "gateway" {
  count           = var.number_of_gateways
  name            = format("irrigation-gateway-%03d", count.index)
  thing_type_name = aws_iot_thing_type.sensor_gateway.name

  attributes = {
    location = "field-01"
    type     = "gateway"
  }
}

resource "aws_iot_certificate" "gateway_cert" {
  count  = var.number_of_gateways
  active = true
}

resource "aws_iot_thing_principal_attachment" "gateway_cert_attachment" {
  count     = var.number_of_gateways
  thing     = aws_iot_thing.gateway[count.index].name
  principal = aws_iot_certificate.gateway_cert[count.index].arn
}

# // S3 // 

resource "aws_iot_topic_rule" "persist_messages" {
  name        = "persist_all_messages"
  description = "Persist all IoT messages to S3"
  enabled     = true
  sql         = "SELECT *, timestamp() as timestamp FROM '+/#'"
  sql_version = "2016-03-23"

  s3 {
    bucket_name = aws_s3_bucket.iot_data.bucket
    key         = "$${topic}/$${timestamp()}"
    role_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LabRole"
  }
}

# // compute //

resource "aws_iot_thing_type" "compute_consumer" {
  name = "compute_consumer"
  properties {
    description = "Compute services"
  }
}

resource "aws_iot_thing" "compute_service" {
  name            = "irrigation-compute"
  thing_type_name = aws_iot_thing_type.compute_consumer.name

  attributes = {
    type = "ComputeService"
  }
}

resource "aws_iot_certificate" "compute_cert" {
  active = true
}

resource "aws_iot_thing_principal_attachment" "compute_cert_attachment" {
  thing     = aws_iot_thing.compute_service.name
  principal = aws_iot_certificate.compute_cert.arn
}
