# 13. Analytics

## LAB PURPOSE

Create component for collecting and processing analytics

## DEFINITIONS
----

### AMAZON KINESIS DATA FIREHOSE 

Amazon Kinesis Data Firehose provides a simple way to capture, transform, and load streaming data

### AMAZON ATHENA

Amazon Athena is an interactive query service that makes it easy to analyze data in Amazon S3 using standard SQL

### AWS STEP FUNCTION

Step Functions automatically manages error handling, retry logic, and state. 

## SNS 

Using Amazon SNS topics, your publisher systems can fanout messages to a large number of subscriber systems including Amazon SQS queues, AWS Lambda

### CREATE ANALYTICS COMPONENT

1. . Inside **modules**  directory create **analytics** directory

2. Inside **analytics** directory create **variables.tf** file

3. Define variables for the the cdn module in the **variables.tf** file

```terraform
variable "application" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "retention_in_days" {
  type        = number
  description = "Logs retentions in days"
  default     = 14
}
```

4. Let's create two bucket one for storing events, and one for storing queries. To do so, create file **s3.tf** in the **analytics** directory and 

```terraform
resource "aws_s3_bucket" "events" {
  bucket = "events-${var.environment}-${var.application}"
  acl    = "private"

  tags = {
    Name        = "events-${var.environment}-${var.application}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "query_output" {
  bucket = "query-output-${var.environment}-${var.application}"
  acl    = "private"

  tags = {
    Name        = "query-output-${var.environment}-${var.application}"
    Environment = var.environment
  }
}
```
6. Create schema for the athena queries. To do so in new file **athena.tf** add 

```terraform
resource "aws_glue_catalog_database" "video_analytics" {
  name = "video-analytics-${var.environment}-${var.application}"
}

resource "aws_glue_catalog_table" "events" {
  database_name = aws_glue_catalog_database.video_analytics.name
  name          = "events-${var.environment}-${var.application}"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    EXTERNAL = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.events.bucket}/"
    input_format  = "org.apache.hadoop.mapred.TextInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.IgnoreKeyTextOutputFormat"

    ser_de_info {
      name                  = "s3-stream"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"

      parameters = {
        "serialization.format" = 1
      }
    }

    columns {
      name = "id"
      type = "string"
    }

    columns {
      name = "userId"
      type = "string"
    }

    columns {
      name = "format"
      type = "string"
    }
    
    columns {
      name = "timestamp"
      type = "timestamp"
    }

  }
}
```


7. Create new file **firehose.tf** where put resources, for insgesting data

```terraform
resource "aws_kinesis_firehose_delivery_stream" "events" {
  name        = "events-stream-${var.environment}-${var.application}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn        = aws_iam_role.firehose_role.arn
    bucket_arn      = aws_s3_bucket.events.arn
    buffer_interval = 60
    buffer_size     = 64

    data_format_conversion_configuration {
      input_format_configuration {
        deserializer {
          open_x_json_ser_de {}
        }
      }
      output_format_configuration {
        serializer {
          parquet_ser_de {}
        }
      }

      schema_configuration {
        database_name = aws_glue_catalog_table.events.database_name
        role_arn      = aws_iam_role.firehose_role.arn
        table_name    = aws_glue_catalog_table.events.name
      }
    }
  }
}


data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "firehose.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = "firehose-role-${var.environment}-${var.application}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "firehose_policy_document" {
  statement {
    actions = [
      "glue:GetTable",
      "glue:GetTableVersion",
      "glue:GetTableVersions"
    ]

    effect = "Allow"
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    effect = "Allow"
    resources = [
      aws_s3_bucket.events.arn,
      "${aws_s3_bucket.events.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "firehose_policy" {
  name   = "firehose-${var.environment}-${var.application}"
  policy = data.aws_iam_policy_document.firehose_policy_document.json
}

resource "aws_iam_role_policy_attachment" "firehose_role_attachement" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}
```


8. Go to **main.tf** file in **ssr** directory and create module **analytics**


```terraform
module "analytics" {
  source      = "./modules/analytics"
  environment = local.environment
  application = var.application
  region      = var.aws_region
}
```

9. Go to **ssr** directory and deploy the infrastructure

```terraforrm
terraform init
```

```terraforrm
terraform plan
```

```terraforrm
terraform apply
```

10. Go to terminal and send some data, several times with different values

```
aws firehose put-record --delivery-stream-name events-stream-dev-blog --record='{"Data":"{\"id\":\"1\",\"userId\":\"1\"}"}' --region "eu-west-1"

aws firehose put-record --delivery-stream-name events-stream-dev-blog --record='{"Data":"{\"id\":\"1\",\"userId\":\"2\"}"}' --region "eu-west-1"

aws firehose put-record --delivery-stream-name events-stream-dev-blog --record='{"Data":"{\"id\":\"1\",\"userId\":\"3\"}"}' --region "eu-west-1"

aws firehose put-record --delivery-stream-name events-stream-dev-blog --record='{"Data":"{\"id\":\"1\",\"userId\":\"4\"}"}' --region "eu-west-1"
```

11. Go to AWS Console, AWS Athena and do some queries 

### CREATE REPORTING COMPONENT

1. In **analytics** directory create **notifications.tf** file with SNS component responsible for sedning notifications to the users. In this file put:

```terraform
resource "aws_sns_topic" "notifications" {
  name = "analytics-notifications-${var.environment}-${var.application}"
}
```

2. Go to AWS Console, SNS service, and subscribe with an email for the created topic

3. Create **functions.tf** file and add the following content to it

```terraform
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
```

4. Copy the contents of the directory source into **src** directory in **analytics** module

5. Create **stage-machine.json** file in **analytics** directory with the following structure

```json

{
  "StartAt": "StartQuery",
  "States": {
    "StartQuery": {
      "Type": "Task",
      "Resource": "${StartQueryExecution}",
      "Next": "GetQueryStatus"
    },
    "GetQueryStatus": {
      "Type": "Task",
      "Resource": "${CheckQueryExecution}",
      "Next": "CheckQueryStatus"
    },
    "CheckQueryStatus": {
      "Type": "Choice",
      "Choices": [
        {
          "Variable": "$.state",
          "StringEquals": "SUCCEEDED",
          "Next": "SendReport"
        },
        {
          "Variable": "$.state",
          "StringEquals": "QUEUED",
          "Next": "Wait"
        },
        {
          "Variable": "$.state",
          "StringEquals": "RUNNING",
          "Next": "Wait"
        }
      ],
      "Default": "Failed"
    },
    "Wait": {
      "Type": "Wait",
      "Seconds": 30,
      "Next": "GetQueryStatus"
    },
    "Failed": {
      "Type": "Fail"
    },
    "SendReport": {
      "Type": "Task",
      "Resource": "${SendReport}",
      "Next": "Done"
    },
    "Done": {
      "Type": "Succeed"
    }
  }
}

```

6. Create **stage-machine.tf** file in **analytics** directory with the following resources

```terraform
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
```

7. Go to **ssr** directory and deploy the infrastructure

```terraforrm
terraform init
```

```terraforrm
terraform plan
```

```terraforrm
terraform apply
```

8. Go to Step functions and start the workflow with the payload

```json
{
  "startDate": "2020-10-10", 
  "endDate" : "2020-10-10"
}

