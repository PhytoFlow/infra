# S3 Bucket and Configuration
resource "random_string" "bucket_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "aws_s3_bucket" "iot_data" {
  bucket = "iot-data-${random_string.bucket_suffix.result}"

  tags = {
    Name        = "iot-data-storage"
    Environment = var.environment
  }
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "iot_data_versioning" {
  bucket = aws_s3_bucket.iot_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "iot_data_encryption" {
  bucket = aws_s3_bucket.iot_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "iot_data_lifecycle" {
  bucket = aws_s3_bucket.iot_data.id

  rule {
    id     = "archive_old_data"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}
