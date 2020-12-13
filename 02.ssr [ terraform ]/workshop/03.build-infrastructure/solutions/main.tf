terraform {
  backend "s3" {
    bucket  = "cd-nextjs-on-the-edge"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}

provider "aws" {
  region  = var.aws_region
}

