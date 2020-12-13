output "db_name_ssm_parameter_arn" {
  description = "DB name SSM parameter ARN"
  value       = aws_ssm_parameter.db_name.arn
}

output "db_user_ssm_parameter_arn" {
  description = "DB user SSM parameter ARN"
  value       = aws_ssm_parameter.db_master_user.arn
}

output "db_password_ssm_parameter_arn" {
  description = "DB password SSM parameter ARN"
  value       = aws_ssm_parameter.db_master_password.arn
}

output "db_host" {
  description = "DB host"
  value       = aws_rds_cluster.db.endpoint
}

output "db_cluster_identifier" {
  description = "DB host"
  value       = aws_rds_cluster.db.cluster_identifier
}
