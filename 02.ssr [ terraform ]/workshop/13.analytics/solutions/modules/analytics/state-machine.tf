data "template_file" "state_machine_json" {
  template = file("${path.module}/state-machine.json")

  vars = {
    StartQueryExecution = aws_lambda_function.start_query_execution.arn
    CheckQueryExecution = aws_lambda_function.check_query_execution.arn
    SendReport          = aws_lambda_function.send_report.arn
  }
}

resource "aws_sfn_state_machine" "state_machine" {
  name     = "analytics-${var.environment}-${var.application}"
  role_arn = aws_iam_role.state_machine_role.arn

  definition = data.template_file.state_machine_json.rendered
}


resource "aws_iam_role" "state_machine_role" {
  name               = "state-machine-role-${var.environment}-${var.application}-analytics"
  assume_role_policy = data.aws_iam_policy_document.state_machine_assume_role_policy.json
}

data "aws_iam_policy_document" "state_machine_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "states.${var.region}.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role_policy_attachment" "state_machine_policy_attachement" {
  role       = aws_iam_role.state_machine_role.name
  policy_arn = aws_iam_policy.state_machine_policy.arn
}

resource "aws_iam_policy" "state_machine_policy" {
  name   = "state-machine-policy-${var.environment}-${var.application}-analytics"
  policy = data.aws_iam_policy_document.state_machine_policy_document.json
}

data "aws_iam_policy_document" "state_machine_policy_document" {
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.environment}-${var.application}*"
    ]
  }
}
