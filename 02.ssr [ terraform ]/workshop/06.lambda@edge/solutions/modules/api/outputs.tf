output "domain_name" {
  value       = aws_api_gateway_stage.stage.invoke_url
  description = "The URL to invoke the API pointing to the stage"
}