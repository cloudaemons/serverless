data "aws_region" "current" {}

resource "aws_iam_role" "api_role" {
  name = "webhooks-api-role-${var.name}-${var.environment}-${var.application}"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "apigateway.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })
}

data "template_file" "gateway_policy" {
  template = file("${path.module}/policies/api-gateway.json")
  vars = {
    sqs = aws_sqs_queue.queue.arn
  }
}

resource "aws_iam_policy" "api_policy" {
  name   = "webhooks-api-policy-${var.name}-${var.environment}-${var.application}"
  policy = data.template_file.gateway_policy.rendered
}

resource "aws_iam_role_policy_attachment" "api_exec_role" {
  role       = aws_iam_role.api_role.name
  policy_arn = aws_iam_policy.api_policy.arn
}

resource "aws_api_gateway_rest_api" "api" {
  name        = "webhooks-api-${var.name}-${var.environment}-${var.application}"
  description = "POST records to SQS queue"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "webhook" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "webhook" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.webhook.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.webhook.id
  http_method             = aws_api_gateway_method.webhook.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  credentials             = aws_iam_role.api_role.arn
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:sqs:path/${aws_sqs_queue.queue.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  request_templates = {
    "application/json" = file("${path.module}/templates/sqs.vtl")
  }

  depends_on = [
    aws_iam_role_policy_attachment.api_exec_role
  ]
}

resource "aws_api_gateway_method_response" "http200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.webhook.id
  http_method = aws_api_gateway_method.webhook.http_method
  status_code = 200
}

resource "aws_api_gateway_integration_response" "http200" {
  rest_api_id       = aws_api_gateway_rest_api.api.id
  resource_id       = aws_api_gateway_resource.webhook.id
  http_method       = aws_api_gateway_method.webhook.http_method
  status_code       = aws_api_gateway_method_response.http200.status_code
  selection_pattern = "^2[0-9][0-9]"

  depends_on = [
    aws_api_gateway_integration.api
  ]
}


resource "aws_api_gateway_usage_plan" "usage_plan" {
  name = "usage-plan-${var.environment}-${var.application}-${var.name}"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = aws_api_gateway_stage.stage.stage_name
  }
}

resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment
}


resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  depends_on = [
    aws_api_gateway_integration.api
  ]

  triggers = {
    redeployment = sha1(join(",", list(
      jsonencode(aws_api_gateway_integration.api),
    )))
  }

  lifecycle {
    create_before_destroy = true
  }
}
