locals {
  project = var.project
  env     = var.env
}

module "vpc" {
  source = "../../../modules/vpc"

  project = var.project
  env     = var.env

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}
