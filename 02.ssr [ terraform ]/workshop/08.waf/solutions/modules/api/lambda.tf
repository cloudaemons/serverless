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
  source_dir  = "${path.module}/src/"

  depends_on = [null_resource.lambda]

}

resource "aws_cloudwatch_log_group" "index" {
  name              = "/aws/lambda/${var.environment}-${var.application}-index"
  retention_in_days = 14
}

resource "aws_lambda_function" "index" {
  description      = "SSR page generator"
  filename         = data.archive_file.lambda_bundle.output_path
  function_name    = "${var.environment}-${var.application}-index"
  handler          = "index.handler"
  memory_size      = 1024
  role             = aws_iam_role.lambda_role.arn
  runtime          = "nodejs12.x"
  source_code_hash = data.archive_file.lambda_bundle.output_base64sha256
  timeout          = 60
  publish          = true

  environment {
    variables = {
      TABLE = var.blog_table_name
    }
  }
}

data "aws_caller_identity" "this" {}

resource "aws_lambda_permission" "index" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.index.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.this.account_id}:${aws_api_gateway_rest_api.api.id}/*/*/*"
}