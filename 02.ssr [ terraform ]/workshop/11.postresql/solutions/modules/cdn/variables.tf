variable "application" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
  default     = "dev"
}

variable "origin_request" {
  type        = string
  description = "Lambda origin request"
}

variable "origin_domain_name" {
  type        = string
  description = "Origin domain nane"
}

variable "orgin_api_domain_name" {
  type = string
  description = "Api gateway name"
}
