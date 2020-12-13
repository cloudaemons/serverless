# 12. Webhooks

## LAB PURPOSE

Create component for receiving webhooks. Component exposes REST API which send all request directly to SQS. All requests then are read by Lambda and send to PostrgreSQL

## DEFINITIONS
----

### SQS

Amazon Simple Queue Service (SQS) is a fully managed message queuing service that enables you to decouple and scale microservices, distributed systems, and serverless applications. SQS eliminates the complexity and overhead associated with managing and operating message oriented middleware, and empowers developers to focus on differentiating work.

## STEPS

### CREATE WEBHOOK COMPONENT

1. . Inside **modules**  directory create **webhooks** directory

2. Inside **webhooks** directory create **variables.tf** file

3. Define variables for the the cdn module in the **variables.tf** file

```terraform
variable "application" {
  type        = string
  description = "Application name"
}

variable "name" {
  type        = string
  description = "Webhook integration name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
}

variable "whitelisted_ip_addresses" {
  type        = list(string)
  description = "Whitelisted IP addresses"
}

variable "delay_seconds" {
  type        = number
  description = "Sqs delay seconds"
}

variable "max_message_size" {
  type        = number
  description = "Sqs max message size"
}

variable "message_retention_seconds" {
  type        = number
  description = "Sqs max retentions time in seconds"
}

variable "receive_wait_time_seconds" {
  type        = number
  description = "Sqs write time in seconds"
}

variable "maxReceiveCount" {
  type        = number
  description = "Sqs max receive count"
}

variable "vpc_id" {
  type        = string
  description = "ID of VPC where all resources should be deployed"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "IDs of privates where all resources should be deployed"
}

variable "sg_id" {
  description = "Seurity group"
}

variable "db_host" {
  description = "Db host"
}
```


4. In the same directory create **sqs.tf** file. Add add resources responsible for queue and dead letter queue

```terraform
resource "aws_sqs_queue" "queue" {
  name                              = "webhooks-${var.name}-${var.environment}-${var.application}"
  delay_seconds                     = var.delay_seconds
  max_message_size                  = var.max_message_size
  message_retention_seconds         = var.message_retention_seconds
  receive_wait_time_seconds         = var.receive_wait_time_seconds
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.maxReceiveCount
  })
}

resource "aws_sqs_queue" "dlq" {
  name                              = "webhooks-${var.name}-dlq-${var.environment}-${var.application}"
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}
```

5. In the same directory create **policies** directory and add file **lambda.json** which contains the policy for function wich wil create later.  The policy you can find below:

```json
{
  "Version": "2012-10-17",
  "Statement": [
      {
        "Action": [
            "sqs:DeleteMessage",
            "sqs:ReceiveMessage",
            "sqs:GetQueueAttributes"
        ],
        "Resource": "${sqs}",
        "Effect": "Allow"
    },
    {
      "Action": [
        "ec2:CreateNetworkInterface",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DeleteNetworkInterface"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },
    {
      "Action": [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*",
      "Effect": "Allow"
    }
  ]
}
```

5. Go to **webhooks** directory and create Lambda which is resposible for reading data from SQS. To do so, please copy **source** directory content into **src**. Then create **lambda.tf** file which contain following resourecs. 

```terraform
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
```

6. Go to **webhooks** directory, and create **waf.tf** file. Waf will protect you API, and limit the usage to only whitelisted IPs. In **waf.tf** file please add following resources

```
resource "aws_wafv2_ip_set" "ipset" {
  name               = "whitelist-${var.environment}-${var.application}-${var.name}"
  description        = "IPV4 to whitelist"
  scope              = "REGIONAL"
  ip_address_version = "IPV4"
  addresses          = var.whitelisted_ip_addresses
}


resource "aws_wafv2_web_acl" "waf" {
  name = "webacl-${var.environment}-${var.application}-${var.name}"

  scope = "REGIONAL"

  default_action {
    block {}
  }

  rule {
    name     = "ip-rate-limit-${var.environment}-${var.application}-${var.name}"
    priority = 0

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = 10000 // MAX 10000 per 5 min
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "ip-rate-rule-metric-${var.environment}-${var.application}-${var.name}"
      sampled_requests_enabled   = false
    }
  }

  rule {
    name     = "ipv4-whitelist-${var.environment}-${var.application}-${var.name}"
    priority = 1

    action {
      allow {}
    }

    statement {
      ip_set_reference_statement {
        arn = aws_wafv2_ip_set.ipset.arn
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rule-ipv4-whitelist-${var.environment}-${var.application}-${var.name}"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "acl-allow-ips-${var.environment}-${var.application}-${var.name}"
    sampled_requests_enabled   = false
  }

}

resource "aws_wafv2_web_acl_association" "waf_association" {
  resource_arn = aws_api_gateway_stage.stage.arn
  web_acl_arn  = aws_wafv2_web_acl.waf.arn
}
```

7. Create policy for **api-gateway.tf**. To do so, in direcory **policies** add **api-gateway.json** . Paste the following policy into it 

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:PutLogEvents",
        "logs:GetLogEvents",
        "logs:FilterLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "sqs:GetQueueUrl",
        "sqs:ChangeMessageVisibility",
        "sqs:ListDeadLetterSourceQueues",
        "sqs:SendMessageBatch",
        "sqs:PurgeQueue",
        "sqs:ReceiveMessage",
        "sqs:SendMessage",
        "sqs:GetQueueAttributes",
        "sqs:ListQueueTags",
        "sqs:ChangeMessageVisibilityBatch",
        "sqs:SetQueueAttributes"
      ],
      "Resource": "${sqs}"
    },
    {
      "Effect": "Allow",
      "Action": "sqs:ListQueues",
      "Resource": "*"
    }      
  ]
}
```

8. In **webhooks** directory create another directory **templates** It is a place where you will put all mappings.

9. Inside **templates** dir add the file **sqs.vtl** with the following content

```vtl
Action=SendMessage&MessageBody=$input.body
```

10. Go to **webhooks** directory and create **api-gateway.tf** file. Add to the file following resources:

```terraform
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
```

11. Create file **outputs.tf** with following outputs:

```terraform

output "api_id" {
  description = "API ID"
  value       = aws_api_gateway_rest_api.api.id
}

output "stage_name" {
  description = "Stage Name"
  value       = aws_api_gateway_stage.stage.stage_name
}
```

12. Go to **main.tf** file in **ssr** directory and create module **webhooks**


```terraform
module "webhooks" {
  source                    = "./modules/webhooks"
  application               = var.application
  name                      = "webhooks"
  environment               = local.environment
  whitelisted_ip_addresses  = ["0.0.0.0/32"]
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 86400
  receive_wait_time_seconds = 10
  maxReceiveCount           = 3
  sg_id                     = module.vpc.sg_id
  vpc_id                    = module.vpc.vpc_id
  private_subnet_ids        = module.vpc.private_subnet_ids
  db_host                   = module.postgresql.db_host
}
```

14. Go to **ssr** directory and deploy the infrastructure

```terraforrm
terraform init
```

```terraforrm
terraform plan
```

```terraforrm
terraform apply
```

15. Go to AWS console to API Gateway and send some data
