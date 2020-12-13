
resource "null_resource" "lambda" {
  provisioner "local-exec" {
    command     = "cd src && ./build.sh"
    working_dir = path.module
  }

  triggers = {
    always_run = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }
}

data "archive_file" "lambda_bundle" {
  type        = "zip"
  output_path = "${path.module}/tmp/bundle.zip"
  source_dir  = "${path.module}/src"
  depends_on  = [null_resource.lambda]
}

resource "aws_lambda_function" "lambda" {
  description                    = "Sends webhook to database"
  filename                       = data.archive_file.lambda_bundle.output_path
  function_name                  = "${var.environment}-${var.application}-${var.name}-sqs-to-db"
  handler                        = "functions/sqs-to-api.handler"
  memory_size                    = 256
  role                           = aws_iam_role.lambda_execution_role.arn
  runtime                        = "nodejs12.x"
  source_code_hash               = data.archive_file.lambda_bundle.output_base64sha256
  timeout                        = 30
  publish                        = true
  reserved_concurrent_executions = 1

  vpc_config {
    security_group_ids = [var.sg_id]
    subnet_ids         = var.private_subnet_ids
  }

  environment {
    variables = {
      DB_HOST = var.db_host
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.sqs_to_api
  ]
}

resource "aws_cloudwatch_log_group" "sqs_to_api" {
  name              = "/aws/lambda/${var.environment}-${var.name}-${var.application}-create-cms-video-assets-object"
  retention_in_days = 14
}

resource "aws_lambda_permission" "allows_sqs_to_trigger_lambda" {
  statement_id  = "AllowExecutionFromSQS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "sqs.amazonaws.com"
  source_arn    = aws_sqs_queue.queue.arn
}

resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  batch_size       = 1
  event_source_arn = aws_sqs_queue.queue.arn
  enabled          = true
  function_name    = aws_lambda_function.lambda.arn
}

resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda-execution-role-${var.name}-${var.environment}-${var.application}"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "Service" : "lambda.amazonaws.com"
        },
        "Effect" : "Allow"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachement" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

data "template_file" "lambda_policy_template" {
  template = file("${path.module}/policies/lambda.json")

  vars = {
    sqs = aws_sqs_queue.queue.arn
  }

}

resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda-policy-${var.name}-${var.environment}-${var.application}"
  policy = data.template_file.lambda_policy_template.rendered
}

