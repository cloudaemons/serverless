variable "application" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
  default     = "dev"
}

variable "region" {
  type        = string
  description = "Region where vpc should be deployed"
  default     = "eu-central-1"
}

variable "vpc_cidr_block" {
  type        = string
  description = "Network cidr block"
  default     = "10.0.0.0/16"
}

variable "subnet_private_one_cidr_block" {
  type        = string
  description = "Private subnet 1 - cidr block"
  default     = "10.0.0.0/24"
}

variable "subnet_private_two_cidr_block" {
  type        = string
  description = "Private subnet 2 - cidr block"
  default     = "10.0.1.0/24"
}

variable "subnet_public_one_cidr_block" {
  type        = string
  description = "Public subnet 1 - cidr block"
  default     = "10.0.2.0/24"
}

variable "subnet_public_two_cidr_block" {
  type        = string
  description = "Public subnet 2 - cidr block"
  default     = "10.0.3.0/24"
}

variable "logs_retention_in_days" {
  type        = number
  description = "VPC flow logs retention period"
  default     = 14
}
