provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = ["./credentials"]
  profile                  = "default"

  # endpoints {
  #   s3              = "http://localhost:4566"
  #   ec2             = "http://localhost:4566"
  #   eks             = "http://localhost:4566"
  #   iam             = "http://localhost:4566"
  #   elasticloadbalancing = "http://localhost:4566"
  # }

  # skip_credentials_validation = true
  # skip_metadata_api_check     = true
  # skip_region_validation      = true
}

module "pulsar" {
  source = "./modules/pulsar"

  environment = var.environment
  aws_region  = var.aws_region
}
