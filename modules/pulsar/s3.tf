resource "random_string" "bucket_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "aws_s3_bucket" "pulsar_offload" {
  bucket = "pulsar-offload-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "pulsar-offload-storage"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "pulsar_offload_versioning" {
  bucket = aws_s3_bucket.pulsar_offload.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "pulsar_offload_encryption" {
  bucket = aws_s3_bucket.pulsar_offload.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
