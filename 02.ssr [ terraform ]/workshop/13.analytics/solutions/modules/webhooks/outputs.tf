output "api_id" {
  description = "API ID"
  value       = aws_api_gateway_rest_api.api.id
}

output "stage_name" {
  description = "Stage Name"
  value       = aws_api_gateway_stage.stage.stage_name
}
