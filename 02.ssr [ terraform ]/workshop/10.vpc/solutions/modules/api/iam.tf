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

resource "aws_iam_role" "lambda_role" {
  name               = "lambda-execution1-role-${var.environment}-${var.application}-api"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_metadata_policy_attachement" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_metadata_policy.arn
}

resource "aws_iam_policy" "lambda_metadata_policy" {
  name   = "lambda-policy1-${var.environment}-${var.application}-api"
  policy = data.aws_iam_policy_document.lambda_metadata_document.json
}

data "aws_iam_policy_document" "lambda_metadata_document" {
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
      "dynamodb:PutItem",
      "dynamodb:GetItem"
    ]
    effect = "Allow"
    resources = [
      var.blog_table_arn
    ]
  }

}
