variable "application" {
  type        = string
  description = "Application name"
}

variable "name" {
  type        = string
  description = "Webhook integration name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
}

variable "whitelisted_ip_addresses" {
  type        = list(string)
  description = "Whitelisted IP addresses"
}

variable "delay_seconds" {
  type        = number
  description = "Sqs delay seconds"
}

variable "max_message_size" {
  type        = number
  description = "Sqs max message size"
}

variable "message_retention_seconds" {
  type        = number
  description = "Sqs max retentions time in seconds"
}

variable "receive_wait_time_seconds" {
  type        = number
  description = "Sqs write time in seconds"
}

variable "maxReceiveCount" {
  type        = number
  description = "Sqs max receive count"
}

variable "vpc_id" {
  type        = string
  description = "ID of VPC where all resources should be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "IDs of privates where all resources should be deployed"
}

variable "sg_id" {
  description = "Seurity group"
}

variable "db_host" {
  description = "Db host"
}
