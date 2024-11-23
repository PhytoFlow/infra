output "iot_vpc_id" {
  value = aws_vpc.iot_vpc.id
}

output "iot_vpc_cidr" {
  value = var.iot_vpc_cidr
}

output "mqtt_endpoint" {
  value = data.aws_iot_endpoint.mqtt
}

output "iot_to_compute_id" {
  value = aws_vpc_peering_connection.iot_compute.id
}

output "s3_bucket_name" {
  value = aws_s3_bucket.iot_data.bucket
}

# Gateway credentials
output "retrieve_gateway_credentials_command" {
  description = "AWS CLI commands to retrieve and save device credentials into separate files"
  value = join(" && ", flatten([
    for i in range(var.number_of_gateways) : [
      "mkdir -p ./${aws_iot_thing.gateway[i].name}",
      "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.gateway_credentials[i].name} --output text --query SecretString > temp.json",
      "cat temp.json | jq -r .certificate_pem > ./${aws_iot_thing.gateway[i].name}/certificate.pem",
      "cat temp.json | jq -r .private_key > ./${aws_iot_thing.gateway[i].name}/private.key",
      "cat temp.json | jq -r .public_key > ./${aws_iot_thing.gateway[i].name}/public.key",
      "cat temp.json | jq -r .thing_name > ./${aws_iot_thing.gateway[i].name}/thing_name.txt",
      "cat temp.json | jq -r .certificate_arn > ./${aws_iot_thing.gateway[i].name}/certificate_arn.txt",
      "rm temp.json"
  ]]))
}

# compute credentials
output "retrieve_compute_credentials_command" {
  description = "AWS CLI command to retrieve compute credentials"
  value = join(" && ", flatten([
    "mkdir -p ./${aws_iot_thing.compute_service.name}",
    "aws secretsmanager get-secret-value --secret-id ${aws_secretsmanager_secret.compute_credentials.name} --output text --query SecretString > temp.json",
    "cat temp.json | jq -r .certificate_pem > ./${aws_iot_thing.compute_service.name}/certificate.pem",
    "cat temp.json | jq -r .private_key > ./${aws_iot_thing.compute_service.name}/private.key",
    "cat temp.json | jq -r .public_key > ./${aws_iot_thing.compute_service.name}/public.key",
    "cat temp.json | jq -r .thing_name > ./${aws_iot_thing.compute_service.name}/thing_name.txt",
    "cat temp.json | jq -r .certificate_arn > ./${aws_iot_thing.compute_service.name}/certificate_arn.txt",
    "rm temp.json"
  ]))
}
