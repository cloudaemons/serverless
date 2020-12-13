# 04. CREATE STORAGE

## LAB PURPOSE

Create S3 bucket and DynamoDB

## DEFINITIONS
----

### AWS S3

Amazon Simple Storage Service (Amazon S3) is an object storage service that offers industry-leading scalability, data availability, security, and performance. This means customers of all sizes and industries can use it to store and protect any amount of data for a range of use cases, such as data lakes, websites, mobile applications, backup and restore, archive, enterprise applications, IoT devices, and big data analytics. Amazon S3 provides easy-to-use management features so you can organize your data and configure finely-tuned access controls to meet your specific business, organizational, and compliance requirements. 

### DYNAMODB

Amazon DynamoDB is a fully managed proprietary NoSQL database service that supports key-value and document data structures

## STEPS

### CREATE S3 BUCKET

1. Create a directory **modules** inside **ssr** directory. It will be a place where all terraform modules will be created. A terraform module is a container for multiple resources that are used together. Modules can be used to create lightweight abstractions, so that you can describe your infrastructure in terms of its architecture, rather than directly in terms of physical objects.

2. Inside **modules**  directory create **storage** directory

3. Inside **storage** directory create two files **s3.tf** and **variables.tf**

4. Define variables for the the storage module in the **variables.tf** file

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

5. Create S3 Bucket in the **s3.tf** file, where all static files will be stored

```terraform
resource "aws_s3_bucket" "origin_bucket" {
  acl = "private"

  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "Origin bucket"
  }
}
```

6. Add the module to the project. In the **main.tf** file in the **ssr** file add
```terraform
module "storage" {
  source                 = "./modules/storage"
  environment            = local.environment
  application            = var.application
}
```

7. Add the locals environment in the same file
```terraforrm
locals {
  environment = "dev"
}
```

8. Add additional environment variables in the **variable.tf** int the **ssr** directory
```terraforrm
variable "application" {
  type        = string
  description = "Application name"
  default     = "blog"
}

```

9. Now it is a time to initialize the terraform, and deploy it to environemnt
```terraforrm
terraform init
```

```terraforrm
terraform plan
```

```terraforrm
terraform apply
```

10. Conirm that you wnat to perform these actions

11. Go to AWS console, and verify that S3 bucket is created

### CREATE DYNAMODB TABLE

1. Inside **storage** directory create **dynamodb.tf** file

2. In newly created file add resource responsible for dynamodb creation

```terraform
resource "aws_dynamodb_table" "blog" {
  name         = "${var.environment}-${var.application}-blog"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "id"
    type = "S"
  }
}
```
3. Create  **outputs.tf** file in the **storage** directory and add the following code there

```terraform
output "blog_table_arn" {
  value = aws_dynamodb_table.blog.arn
}

output "blog_table_name" {
  value = aws_dynamodb_table.blog.id
}

output "origin_domain_name" {
  value = aws_s3_bucket.origin_bucket.bucket_regional_domain_name
}

output "origin_bucket_arn" {
  value = aws_s3_bucket.origin_bucket.arn
}

output "origin_bucket_name" {
  value = aws_s3_bucket.origin_bucket.id
}
```

4. Go to **ssr** directory and deploy the infrastructure

```terraforrm
terraform init
```

```terraforrm
terraform plan
```

```terraforrm
terraform apply
```

4. Conirm that you wnat to perform these actions

5. Go to AWS console and verify if table is created

