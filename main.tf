provider "aws" {
  region                   = var.aws_region
  shared_credentials_files = ["./credentials"]
  profile                  = "default"
}

module "iot" {
  source = "./modules/iot"

  environment            = var.environment
  aws_region             = var.aws_region
  compute_sg_id          = module.compute.compute_sg_id
  compute_private_rt_id  = module.compute.compute_private_rt_id
  compute_vpc_cidr_block = module.compute.compute_vpc_cidr_block
  compute_vpc_id         = module.compute.compute_vpc_id
}

module "compute" {
  source = "./modules/compute"

  environment       = var.environment
  aws_region        = var.aws_region
  iot_vpc_id        = module.iot.iot_vpc_id
  iot_vpc_cidr      = module.iot.iot_vpc_cidr
  iot_to_compute_id = module.iot.iot_to_compute_id
}
