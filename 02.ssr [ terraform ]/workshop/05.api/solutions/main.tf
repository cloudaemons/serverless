locals {
  environment = "dev"
}

terraform {
  backend "s3" {
    bucket  = "arekzegarek"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region  = var.aws_region
}

module "storage" {
  source                 = "./modules/storage"
  environment            = local.environment
  application            = var.application
}

module "api" {
  source          = "./modules/api"
  environment     = local.environment
  application     = var.application
  region          = var.aws_region
  blog_table_name = module.storage.blog_table_name
  blog_table_arn  = module.storage.blog_table_arn
}
