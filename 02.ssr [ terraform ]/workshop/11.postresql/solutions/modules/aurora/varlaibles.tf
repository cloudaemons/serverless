variable "application" {
  description = "Application name"
}

variable "environment" {
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
}

variable "backup_retention_period" {
  type    = number
  default = 7
}

variable "preferred_backup_window" {
  default = "02:00-05:00"
}

variable "preferred_maintenance_window" {
  default = "sun:01:00-sun:01:30"
}

variable "scaling_min_capacity" {
  type    = number
  default = 2
}

variable "scaling_max_capacity" {
  type    = number
  default = 4
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Whether to skip a final database snapshot"
}

variable "sg_id" {
  description = "SG ID to be assigned to a database cluster"
}

variable "db_subnet_ids" {
  type        = list(string)
  description = "List of VPC subnets ids for placing database cluster"
}

variable "vpc_id" {
  type =  string
  description = "VPC ID"
}