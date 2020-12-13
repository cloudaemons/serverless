# 05. CREATE LAMBDA@EDGE 

## LAB PURPOSE

Create Lambda@Edge which is able to modify headers sent to origin

## DEFINITIONS
----

### LAMBDA@EDGE 

Lambda@Edge is a feature of Amazon CloudFront that lets you run code closer to users of your application, which improves performance and reduces latency. With Lambda@Edge, you can enrich your web applications by making them globally distributed and improving their performance — all with zero server administration.


## STEPS

### CREATE LAMBDA FUNCTION

1. Inside **modules**  directory create **lambda-at-edge** directory

2. Inside **lambda-at-edge** directory create two files **lambda.tf** and **variables.tf**

3. Define variables for the the api module in the **variables.tf** file

```terraform
variable "application" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
}
```

4. Now let's prepare the code to be run on lambda function. To do so, copy **src** directory into **lambda-at-edge** directory

5. Change the lambda code. You have to change the value **YOUR_API_KEY** . 

```
exports.handler = async (event, context) => {
  const request = event.Records[0].cf.request
  request.headers['x-api-key'] = [{ key: 'x-api-key', value: 'YOUR_API_KEY' }]
  return request
}
```


6.  To get the value of API_KEY go to AWS console **API GATEWAY** service **https://eu-west-1.console.aws.amazon.com/apigateway/home?region=eu-west-1#/api-keys**

7. Find your key, click on it, then click the **Show** button

8. Put the value to your code

9. Add to the **lambda.tf**  resource to create  **bundle.zip** file every time the terraform is triggered   

```terraform
data "archive_file" "lambda_bundle" {
  type        = "zip"
  output_path = "${path.module}/tmp/bundle.zip"
  source_dir  = "${path.module}/src"
}

```

10. Let's prepare the file with permission which lambda require when it is running , to do so create **iam.tf**. In the file add permission for creating logs

```terraform
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "edgelambda.amazonaws.com",
        "lambda.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "lambda_execution_role" {
  name               = "lambda-execution-role-${var.environment}-${var.application}"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "lambda_policy_document" {
  statement {
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    effect    = "Allow"
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_policy" {
  name   = "lambda-edge-policy-${var.environment}-${var.application}"
  policy = data.aws_iam_policy_document.lambda_policy_document.json
}


resource "aws_iam_role_policy_attachment" "lambda_policy_attachement" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

```

11. Create Lambda function in the **lambda.tf** file

```terraform
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
```

12. Create **outputs.tf** file inside the **lambda-at-edge** directory. And then add following code

```terraform
output "origin_request" {
  description = "ARN of lambda at edge"
  value       = aws_lambda_function.lambda.qualified_arn
}
```

13. Lambda ad edge should be deployed in **us-east-1** region. To do so you have to create new AWS provider. In the **main.tf** file in the **ssr** directory add

```terraform
provider "aws" {
  alias   = "us-east-1"
  region  = "us-east-1"
}
```

14. Add the module to the project. In the **main.tf** file in the **ssr** directory add
```terraform
module "lambda_at_edge" {
  source      = "./modules/lambda-at-edge"
  environment = local.environment
  application = var.application
  providers = {
    aws = aws.us-east-1
  }
}
```

15. Go to **ssr** directory and deploy the infrastructure

```terraforrm
terraform init
```

```terraforrm
terraform plan
```

```terraforrm
terraform apply
```

16. Go to AWS console and verify if lambda is created

