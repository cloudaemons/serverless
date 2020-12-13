data "archive_file" "lambda_bundle" {
  type        = "zip"
  output_path = "${path.module}/tmp/bundle.zip"
  source_dir  = "${path.module}/src"
}

resource "aws_lambda_function" "lambda" {
  description      = "Function to run nextjs"
  filename         = data.archive_file.lambda_bundle.output_path
  function_name    = "lambda-edge-${var.environment}-${var.application}"
  handler          = "index.handler"
  memory_size      = 128
  role             = aws_iam_role.lambda_execution_role.arn
  runtime          = "nodejs12.x"
  source_code_hash = data.archive_file.lambda_bundle.output_base64sha256
  timeout          = 3
  publish          = true
}

