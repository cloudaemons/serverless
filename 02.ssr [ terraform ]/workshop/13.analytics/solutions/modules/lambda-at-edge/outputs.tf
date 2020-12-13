output "origin_request" {
  description = "ARN of lambda at edge"
  value       = aws_lambda_function.lambda.qualified_arn
}
