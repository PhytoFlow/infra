variable "environment" {
  description = "Environment name"
  type        = string
}

variable "pulsar_vpc_cidr" {
  description = "CIDR block for Pulsar VPC"
  default     = "10.0.0.0/24"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}