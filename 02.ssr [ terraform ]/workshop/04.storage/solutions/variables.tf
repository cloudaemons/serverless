variable "aws_region" {
  type        = string
  description = "Region where application should be deployed"
  default     = "eu-west-1"
}

variable "application" {
  type        = string
  description = "Application name"
  default     = "blog"
}

