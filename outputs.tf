output "mqtt_endpoint" {
  value = module.iot.mqtt_endpoint
}

output "s3_bucket_name" {
  value = module.iot.s3_bucket_name
}

output "retrieve_gateway_credentials_command" {
  value = module.iot.retrieve_gateway_credentials_command
}

output "retrieve_compute_credentials_command" {
  value = module.iot.retrieve_compute_credentials_command
}
