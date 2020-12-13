data "aws_availability_zones" "available" {
  all_availability_zones = true

  exclude_names = ["eu-west-1c"]
}

resource "random_string" "db_name" {
  special   = false
  number    = false
  length    = 20
  min_upper = 4
}

resource "aws_ssm_parameter" "db_name" {
  name  = "/${var.environment}/${var.application}/aurora/db_name"
  type  = "String"
  value = random_string.db_name.result
}

resource "random_string" "db_master_user" {
  special   = false
  number    = false
  length    = 24
  min_upper = 4
}

resource "aws_ssm_parameter" "db_master_user" {
  name  = "/${var.environment}/${var.application}/aurora/db_master_user"
  type  = "String"
  value = random_string.db_master_user.result
}

resource "random_password" "db_master_password" {
  special     = false
  length      = 32
  min_numeric = 4
  min_upper   = 4
}

resource "aws_ssm_parameter" "db_master_password" {
  name  = "/${var.environment}/${var.application}/aurora/db_master_password"
  type  = "SecureString"
  value = random_password.db_master_password.result
}

resource "random_string" "final_snapshot_suffix" {
  special = false
  length  = 8
}

resource "aws_db_subnet_group" "db" {
  subnet_ids = var.db_subnet_ids
}

resource "aws_rds_cluster" "db" {
  cluster_identifier           = "${var.environment}-${var.application}"
  engine_mode                  = "serverless"
  engine                       = "aurora-postgresql"
  engine_version               = "10.7"
  availability_zones           = data.aws_availability_zones.available.names
  database_name                = random_string.db_name.result
  master_username              = random_string.db_master_user.result
  master_password              = random_password.db_master_password.result
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window
  skip_final_snapshot          = var.skip_final_snapshot
  final_snapshot_identifier    = "${var.environment}-${var.application}-${random_string.final_snapshot_suffix.result}"
  storage_encrypted            = true
  vpc_security_group_ids       = [aws_security_group.db.id]
  db_subnet_group_name         = aws_db_subnet_group.db.name

  scaling_configuration {
    auto_pause               = false
    min_capacity             = var.scaling_min_capacity
    max_capacity             = var.scaling_max_capacity
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }

  lifecycle {
    ignore_changes  = [availability_zones, engine_version]
    prevent_destroy = true
  }
}
