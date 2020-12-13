# 03. BUILD INFRASTRUCTURE

## LAB PURPOSE

Create your first infrastructure with terraform

## DEFINITIONS
----
### TERRAFORM

Terraform is a tool for building, changing, and versioning infrastructure safely and efficiently. Terraform can manage existing and popular service providers as well as custom in-house solutions.

## STEPS

### INSTALL TERRAFORM

1. Go to **Cloud9** web console.
2. Create directory **ssr**
3. Create two files in this directory **main.tf** and **variables.tf**
4. Open **variables.tf** file. This file should contains inputs variables which serve as parameters for a Terraform module, allowing aspects of the module to be customized without altering the module's own source code
5. Create input variable in the file and save it
```terraform
variable "aws_region" {
  type        = string
  description = "Region where application should be deployed"
  default     = "eu-west-1"
}
```
6. Open **main.tf** file. 
7. Create Terraform settings. Terraform settings are gathered together into terraform blocks. You need to configure your backend

```terraform
terraform {
  backend "s3" {
    bucket  = "<name of your bucket created ealier>"
    key     = "terraform.tfstate"
    region  = "eu-west-1"
    encrypt = true
  }
}
```

8. Now, let's create a provider. A provider is responsible for understanding API interactions and exposing resources. Here you can see all available providers **https://www.terraform.io/docs/providers/index.html**.  For the purpose of this course we will be using only **AWS provider** which is described here **https://registry.terraform.io/providers/hashicorp/aws/latest/docs**. Familiarize with this docummentation, it will be helpful later on. To create provider you have add this code to your file

```terraform
provider "aws" {
  region  = var.aws_region
}
```

9. Now it is a time to initialize the terraform, and deploy it to environemnt, in the **Cloud9** terminal run
```terraforrm
terraform init
```

```terraforrm
terraform plan
```

```terraforrm
terraform apply
```

10. At this step you should have created skeleton for you infrastructure