data "template_file" "api_documentation" {
  template = file("${path.module}/open-api/template.yaml")

  vars = {
    api_name = "api-gateway-${var.environment}-${var.application}"
    region   = var.region
    timeout  = 29000
    index    = aws_lambda_function.index.arn
  }
}

resource "aws_api_gateway_rest_api" "api" {
  name = "api-gateway-${var.environment}-${var.application}"
  body = data.template_file.api_documentation.rendered

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_api_key" "api_key" {
  name = "api-key-${var.environment}-${var.application}"
}

resource "aws_api_gateway_deployment" "stage" {
  depends_on  = [aws_api_gateway_rest_api.api]
  rest_api_id = aws_api_gateway_rest_api.api.id
}

resource "aws_api_gateway_stage" "stage" {
  depends_on    = [aws_api_gateway_rest_api.api]
  deployment_id = aws_api_gateway_deployment.stage.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment
}

resource "aws_api_gateway_usage_plan" "usage_plan" {
  depends_on = [aws_api_gateway_stage.stage]
  name       = "usage-plan-${var.environment}-${var.application}"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = var.environment
  }
}

