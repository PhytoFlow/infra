# Variables
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "iot_vpc_cidr" {
  description = "CIDR block for IoT VPC"
  default     = "10.0.0.0/16"
  type        = string
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.128.0/24", "10.0.129.0/24"]
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "number_of_gateways" {
  description = "Number of IoT gateways to create"
  type        = number
  default     = 2
}

variable "compute_sg_id" {
  description = "Security Group ID from the compute side"
}

variable "compute_private_rt_id" {
  description = "Compute private routing table for VPC peering"
}

variable "compute_vpc_cidr_block" {
  description = "Compute VPC CIDR block"
}

variable "compute_vpc_id" {
  description = "Compute VPC ID"
}