variable "application" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "retention_in_days" {
  type        = number
  description = "Logs retentions in days"
  default     = 14
}
