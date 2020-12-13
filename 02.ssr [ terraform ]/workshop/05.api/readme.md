# 05. CREATE API 

## LAB PURPOSE

Create API Gateway and AWS Lambda for render and serve contenent

## DEFINITIONS
----

### AWS LAMBDA

AWS Lambda allow you to run code without provisioning or managing servers. You pay only for the compute time you consume - there is no charge when your code is not running.

### API GATEWAY

Amazon API Gateway is an AWS service for creating, publishing, maintaining, monitoring, and securing REST, HTTP, and WebSocket APIs at any scale.

## STEPS

### CREATE LAMBDA FUNCTION

1. Inside **modules**  directory create **api** directory

2. Inside **api** directory create two files **lambda.tf** and **variables.tf**

3. Define variables for the the api module in the **variables.tf** file

```terraform
variable "application" {
  description = "Application name"
}

variable "environment" {
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
}

variable "region" {
  description = "Region where vpc should be deployed"
}

variable "blog_table_name" {
  description = "Blog table name"
}

variable "blog_table_arn" {
  description = "Blog table arn"
}
```

4. Now let's prepare the nextjs code to be run on lambda function. To do so, copy **src** directory into **api** directory

5. Inside the directory **src** you have files responsible for the serving & rendering pages, analyze the code. Next run ```npm install``` and ```npm run build``` in terminal inside **src** directory to verify if the code compile

6. Add to the **lambda.tf** code that triggers the proccess of building package, needed to be serve via lambda 

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
```

7. Inside the same file add resource to create  **bundle.zip** file every time the terraform is triggered  

```terraform
data "archive_file" "lambda_bundle" {
  type        = "zip"
  output_path = "${path.module}/tmp/bundle.zip"
  source_dir  = "${path.module}/src/"

  depends_on = [null_resource.lambda]

}
```

8. In the **lambda.tf** file add. 
```
resource "aws_cloudwatch_log_group" "index" {
  name              = "/aws/lambda/${var.environment}-${var.application}-index"
  retention_in_days = 14
}
```
The code is responsible for setting retention of cloud watch logs


9. Let's prepare the file with permission which lambda require when it is running , to do so create **iam.tf** in **api** directory. In the file add permission for creating logs, and access to dynamodb created ealier

```terraform
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
  name               = "lambda-execution-role-${var.environment}-${var.application}-api"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "lambda_metadata_policy_attachement" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_metadata_policy.arn
}

resource "aws_iam_policy" "lambda_metadata_policy" {
  name   = "lambda-policy-${var.environment}-${var.application}-api"
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
```

10. Next create Lambda function in the **lambda.tf** file

```terraform
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
```

11. Add the module to the project. In the **main.tf** file in the **ssr** directory add
```terraform
module "api" {
  source          = "./modules/api"
  environment     = local.environment
  application     = var.application
  region          = var.aws_region
  blog_table_name = module.storage.blog_table_name
  blog_table_arn  = module.storage.blog_table_arn
}
```

12. Go to **ssr** directory and deploy the infrastructure

```terraforrm
terraform init
```

```terraforrm
terraform plan
```

```terraforrm
terraform apply
```

13. Test your lambda in the AWS console, to do so go to **https://eu-west-1.console.aws.amazon.com/lambda/home?region=eu-west-1#/functions/dev-blog-index** 

14. Click **Test** button

15. From the **Event template** list chose **Amazon API Gateway Proxy** then add the **Event name** and click create

16. Click **Test** button again, you should see **green screen** with 404 error 

### CREATE API GATEWAY

1. Now is a time to create API Gateway, to do so we have to create open API specification. Analyze the code below, then create direcory **open-api** inside **api** directory. In **open-api** directory add file **template.yaml** and add the code there. 

```yaml
openapi: "3.0.1"
info:
  title: ${api_name}
  version: "2020-11-27T12:18:31Z"

x-amazon-apigateway-policy:
  Version: "2012-10-17"
  Statement:
    - Effect: Allow
      Principal: "*"
      Action:
        - execute-api:Invoke
      Resource: "*"

paths:
  /{proxy+}:
    get:
      security:
      - api_key: []
      x-amazon-apigateway-integration:
        uri: "arn:aws:apigateway:${region}:lambda:path/2015-03-31/functions/${index}/invocations"
        passthroughBehavior: "when_no_match"
        httpMethod: "POST"
        timeoutInMillis: ${timeout}
        type: "aws_proxy"
          
components:
  securitySchemes:
    api_key:
      type: "apiKey"
      name: "x-api-key"
      in: "header"
```

2. In **api** directory create **api-gateway.tf** file

3. In this file create resource which is able to parse the open api specificatioon

```terraform
data "template_file" "api_documentation" {
  template = file("${path.module}/open-api/template.yaml")

  vars = {
    api_name = "api-gateway-${var.environment}-${var.application}"
    region   = var.region
    timeout  = 29000
    index    = aws_lambda_function.index.arn
  }
}
```

4. Create api gateway resource in **api-gateway** file

```terraform
resource "aws_api_gateway_rest_api" "api" {
  name = "api-gateway-${var.environment}-${var.application}"
  body = data.template_file.api_documentation.rendered

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}
```

5. Create api key, to protect our api

```terraform
resource "aws_api_gateway_api_key" "api_key" {
  name = "api-key-${var.environment}-${var.application}"
}
```

6. Create api gateway deployment

```terraform
resource "aws_api_gateway_deployment" "stage" {
  depends_on  = [aws_api_gateway_rest_api.api]
  rest_api_id = aws_api_gateway_rest_api.api.id
}
```

7. Create api gateway deployment

```terraform
resource "aws_api_gateway_stage" "stage" {
  depends_on    = [aws_api_gateway_rest_api.api]
  deployment_id = aws_api_gateway_deployment.stage.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = var.environment
}
```

8. Create api gateway stage
```terraform
resource "aws_api_gateway_usage_plan" "usage_plan" {
  depends_on = [aws_api_gateway_stage.stage]
  name       = "usage-plan-${var.environment}-${var.application}"

  api_stages {
    api_id = aws_api_gateway_rest_api.api.id
    stage  = var.environment
  }
}
```

9. Let's add permission for API Gateway to invoke a lambda, to do so please add following code in the **lambda.tf** file

```terraform

data "aws_caller_identity" "this" {}

resource "aws_lambda_permission" "index" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.index.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.region}:${data.aws_caller_identity.this.account_id}:${aws_api_gateway_rest_api.api.id}/*/*/*"
}
```

10. In the **api** directory create **output.tf** file and put code listed below

```terraform
output "domain_name" {
  value       = aws_api_gateway_stage.stage.invoke_url
  description = "The URL to invoke the API pointing to the stage"
}
```

11. Go to **ssr** directory and deploy the infrastructure

```terraforrm
terraform init
```

```terraforrm
terraform plan
```

```terraforrm
terraform apply
```

12. Go to AWS console **https://eu-west-1.console.aws.amazon.com/apigateway/main/apis?region=eu-west-1** find the **api-gateway-dev-blog** click on it

13. Click **{proxy+}**
14. Next click **GET**
15. Next click **Test**
16. For the proxy value put **about**
17. Click **Test** , you should see on the right side that you have in response body response with 200 status code
18. Check the same for **index** page