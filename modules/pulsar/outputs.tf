output "ssh_public_key" {
  value = tls_private_key.pulsar_ssh_key.public_key_openssh
}

output "s3_bucket_name" {
  value = aws_s3_bucket.pulsar_offload.bucket
}

output "eks_endpoint" {
  value = aws_eks_cluster.pulsar_cluster.endpoint
}

output "node_group_role" {
  value = aws_iam_role.eks_node_group_role.arn
}

output "mqtt_elastic_ip" {
  value = aws_eip.mqtt_endpoint.public_ip
}

output "mqtt_tls_cert" {
  value     = tls_self_signed_cert.mqtt_cert.cert_pem
  sensitive = true
}

output "mqtt_tls_key" {
  value     = tls_private_key.mqtt_key.private_key_pem
  sensitive = true
}