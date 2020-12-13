resource "null_resource" "lambda" {
  provisioner "local-exec" {
    command     = "cd src && npm install && npm prune --production"
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

  depends_on = [null_resource.lambda]

}

resource "aws_lambda_function" "start_query_execution" {
  description      = "Start Athena Query Execution"
  filename         = data.archive_file.lambda_bundle.output_path
  function_name    = "${var.environment}-${var.application}-start-query-execution"
  handler          = "functions/start-query-execution.handler"
  memory_size      = 256
  role             = aws_iam_role.lambda_execution_role.arn
  runtime          = "nodejs12.x"
  source_code_hash = data.archive_file.lambda_bundle.output_base64sha256
  timeout          = 60
  publish          = true

  environment {
    variables = {
      ATHENA_DATABASE     = element(split(":", aws_glue_catalog_table.events.id), 1)
      EVENTS_TABLE = element(split(":", aws_glue_catalog_table.events.id), 2)
      S3_QUERY_OUTPUT     = aws_s3_bucket.query_output.bucket
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.start_query_execution,
    null_resource.lambda
  ]
}

resource "aws_cloudwatch_log_group" "start_query_execution" {
  name              = "/aws/lambda/${var.environment}-${var.application}-start-query-execution"
  retention_in_days = var.retention_in_days
}

resource "aws_lambda_function" "check_query_execution" {
  description      = "Check Athena Query Execution"
  filename         = data.archive_file.lambda_bundle.output_path
  function_name    = "${var.environment}-${var.application}-check-query-execution"
  handler          = "functions/check-query-execution.handler"
  memory_size      = 256
  role             = aws_iam_role.lambda_execution_role.arn
  runtime          = "nodejs12.x"
  source_code_hash = data.archive_file.lambda_bundle.output_base64sha256
  timeout          = 60
  publish          = true

  depends_on = [
    aws_cloudwatch_log_group.check_query_execution,
    null_resource.lambda
  ]
}

resource "aws_cloudwatch_log_group" "check_query_execution" {
  name              = "/aws/lambda/${var.environment}-${var.application}-check-query-execution"
  retention_in_days = var.retention_in_days
}

resource "aws_lambda_function" "send_report" {
  description      = "Send Analytics"
  filename         = data.archive_file.lambda_bundle.output_path
  function_name    = "${var.environment}-${var.application}-send-report"
  handler          = "functions/send-report.handler"
  memory_size      = 256
  role             = aws_iam_role.lambda_execution_role.arn
  runtime          = "nodejs12.x"
  source_code_hash = data.archive_file.lambda_bundle.output_base64sha256
  timeout          = 60
  publish          = true

  environment {
    variables = {
      SNS_TOPIC = aws_sns_topic.notifications.arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.send_report,
    null_resource.lambda
  ]
}

resource "aws_cloudwatch_log_group" "send_report" {
  name              = "/aws/lambda/${var.environment}-${var.application}-send-report"
  retention_in_days = var.retention_in_days
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "lambda_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda-execution-role-${var.environment}-${var.application}-analytics"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachement" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda-policy-${var.environment}-${var.application}-analytics"
  policy = data.aws_iam_policy_document.lambda_policy_document.json
}

data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    actions = [
      "sns:Publish"
    ]
    effect = "Allow"
    resources = [
      aws_sns_topic.notifications.arn
    ]
  }

  statement {
    actions = [
      "states:StartExecution"
    ]
    effect = "Allow"
    resources = [
      aws_sfn_state_machine.state_machine.arn
    ]
  }

  statement {
    actions = [
      "athena:StartQueryExecution",
      "athena:Get*",
      "glue:GetTable"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }

  statement {
    actions = [
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload",
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.query_output.arn,
      "${aws_s3_bucket.query_output.arn}/*",
      aws_s3_bucket.events.arn,
      "${aws_s3_bucket.events.arn}/*"
    ]
  }
}

resource "aws_lambda_function" "start_analytics_workflow" {
  description      = "Start Analytics Workflow"
  filename         = data.archive_file.lambda_bundle.output_path
  function_name    = "${var.environment}-${var.application}-start-analytics-workflow"
  handler          = "functions/start-analytics-workflow.handler"
  memory_size      = 256
  role             = aws_iam_role.lambda_execution_role.arn
  runtime          = "nodejs12.x"
  source_code_hash = data.archive_file.lambda_bundle.output_base64sha256
  timeout          = 60
  publish          = true

  environment {
    variables = {
      STATE_MACHINE_ARN = aws_sfn_state_machine.state_machine.arn
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.start_query_execution,
    null_resource.lambda
  ]
}

resource "aws_cloudwatch_log_group" "start_analytics_workflow" {
  name              = "/aws/lambda/${var.environment}-${var.application}-start-analytics-workflow"
  retention_in_days = var.retention_in_days
}

resource "aws_cloudwatch_event_rule" "once_a_month" {
  name                = "send-report-once-a-month-${var.environment}-${var.application}"
  description         = "Run at 8:00 am (UTC) every 1st day of the month"
  schedule_expression = "cron(0 8 1 * ? *)"
}

resource "aws_cloudwatch_event_target" "once_a_month" {
  rule      = aws_cloudwatch_event_rule.once_a_month.name
  target_id = "send-report-once-a-month-${var.environment}-${var.application}"
  arn       = aws_lambda_function.start_analytics_workflow.arn
}

resource "aws_lambda_permission" "permission_start_analytics_workflow" {
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_analytics_workflow.arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.once_a_month.arn
}
