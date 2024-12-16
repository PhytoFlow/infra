resource "aws_iot_policy" "gateway_policy" {
  name = "irrigation-gateway-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iot:Connect"]
        Resource = ["arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:client/irrigation-gateway-*"]
        Condition = {
          StringLike = {
            "iot:ClientId" : ["irrigation-gateway-*"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = ["iot:Publish"]
        Resource = [
          # Sensor data topics
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/sensors/+/data",
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/gateway/status",
          # Error and diagnostics
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/errors",
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/diagnostics"
        ]
      },
      {
        Effect = "Allow"
        Action = ["iot:Subscribe"]
        Resource = [
          # Control commands
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topicfilter/irrigation/control/+/command",
          # System updates
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topicfilter/irrigation/system/updates"
        ]
      },
      {
        Effect = "Allow"
        Action = ["iot:Receive"]
        Resource = [
          # Control commands
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/control/+/command",
          # System updates
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/system/updates"
        ]
      }
    ]
  })
}

# compute Consumer Policy
resource "aws_iot_policy" "compute_policy" {
  name = "irrigation-compute-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["iot:Connect"]
        Resource = ["arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:client/irrigation-compute-*"]
        Condition = {
          StringLike = {
            "iot:ClientId" : ["irrigation-compute-*"]
          }
        }
      },
      {
        Effect = "Allow"
        Action = ["iot:Subscribe"]
        Resource = [
          # Subscribe to all sensor data
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topicfilter/irrigation/sensors/+/data",
          # Gateway status
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topicfilter/irrigation/gateway/status",
          # Errors and diagnostics
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topicfilter/irrigation/errors",
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topicfilter/irrigation/diagnostics"
        ]
      },
      {
        Effect = "Allow"
        Action = ["iot:Receive"]
        Resource = [
          # Receive all sensor data
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/sensors/+/data",
          # Gateway status
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/gateway/status",
          # Errors and diagnostics
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/errors",
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/diagnostics"
        ]
      },
      {
        Effect = "Allow"
        Action = ["iot:Publish"]
        Resource = [
          # Control commands
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/control/+/command",
          # System updates
          "arn:aws:iot:${var.aws_region}:${data.aws_caller_identity.current.account_id}:topic/irrigation/system/updates"
        ]
      }
    ]
  })
}


resource "aws_vpc_endpoint_policy" "s3_policy" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.iot_data.arn,
          "${aws_s3_bucket.iot_data.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iot_policy_attachment" "gateway_policy_attachment" {
  count  = var.number_of_gateways
  policy = aws_iot_policy.gateway_policy.name
  target = aws_iot_certificate.gateway_cert[count.index].arn
}

resource "aws_iot_policy_attachment" "compute_policy_attachment" {
  policy = aws_iot_policy.compute_policy.name
  target = aws_iot_certificate.compute_cert.arn
}


