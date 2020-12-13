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
  region = var.aws_region
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

module "storage" {
  source                 = "./modules/storage"
  environment            = local.environment
  application            = var.application
  origin_access_identity = module.cdn.origin_access_identity
}

module "api" {
  source          = "./modules/api"
  environment     = local.environment
  application     = var.application
  region          = var.aws_region
  blog_table_name = module.storage.blog_table_name
  blog_table_arn  = module.storage.blog_table_arn
  cognito_arn     = module.user_directory.cognito_arn
}

module "lambda_at_edge" {
  source      = "./modules/lambda-at-edge"
  environment = local.environment
  application = var.application
  providers = {
    aws = aws.us-east-1
  }
}

module "cdn" {
  source                = "./modules/cdn"
  environment           = local.environment
  origin_domain_name    = module.storage.origin_domain_name
  orgin_api_domain_name = trimprefix(trimsuffix(module.api.domain_name, "/${local.environment}"), "https://")
  application           = var.application
  origin_request        = module.lambda_at_edge.origin_request

  providers = {
    aws = aws.us-east-1
  }
}

module "user_directory" {
  source      = "./modules/user-directory"
  environment = local.environment
  application = var.application
  region      = var.aws_region
}

module "vpc" {
  source      = "./modules/vpc"
  environment = local.environment
  application = var.application
  region      = var.aws_region
}

module "postgresql" {
  source = "./modules/aurora"

  application         = var.application
  environment         = local.environment
  skip_final_snapshot = true
  vpc_id              = module.vpc.vpc_id
  sg_id               = module.vpc.sg_id
  db_subnet_ids       = module.vpc.private_subnet_ids
}

module "webhooks" {
  source                    = "./modules/webhooks"
  application               = var.application
  name                      = "webhooks"
  environment               = local.environment
  whitelisted_ip_addresses  = ["0.0.0.0/32"]
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  maxReceiveCount           = 3
  sg_id                     = module.vpc.sg_id
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  db_host                   = module.postgresql.db_host
}

module "analytics" {
  source      = "./modules/analytics"
  environment = local.environment
  application = var.application
  region      = var.aws_region
}

