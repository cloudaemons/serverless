data "aws_iam_policy_document" "flow_logs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "vpc-flow-logs.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "flow_logs_to_cloudwatch" {
  name               = "flow-logs-to-cloudwatch-${var.application}-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.flow_logs_assume_role_policy.json
}

data "aws_iam_policy_document" "flow_logs_to_cloudwatch" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "flow_logs_to_cloudwatch" {
  name   = "flow-logs-to-cloudwatch-${var.application}-${var.environment}"
  policy = data.aws_iam_policy_document.flow_logs_to_cloudwatch.json
}

resource "aws_iam_role_policy_attachment" "flow_logs_to_cloudwatch" {
  role       = aws_iam_role.flow_logs_to_cloudwatch.name
  policy_arn = aws_iam_policy.flow_logs_to_cloudwatch.arn
}
