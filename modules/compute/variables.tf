variable "environment" {
  description = "Environment name"
  type        = string
}

variable "compute_vpc_cidr" {
  description = "CIDR block for Compute VPC"
  default     = "10.1.0.0/16"
  type        = string
}

variable "iot_vpc_cidr" {
  description = "CIDR block for IOT VPC"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "iot_vpc_id" {
  description = "IoT VPC ID"
}

variable "iot_to_compute_id" {
  description = "ID of the IOT VPC Peering config"
}
