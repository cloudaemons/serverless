# 07. Amazon CloudFront

## LAB PURPOSE

Create CDN

## DEFINITIONS
----

### AWS CLOUDFRONT

Amazon CloudFront is a fast content delivery network (CDN) service that securely delivers data, videos, applications, and APIs to customers globally with low latency, high transfer speeds, all within a developer-friendly environment.

## STEPS

### CREATE CDN DISTRIBUTION

1. Inside **modules**  directory create **cdn** directory

2. Inside **cdn** directory create three files **main.tf** and **variables.tf** and **outputs.tf**

3. Define variables for the the cdn module in the **variables.tf** file

```terraform
variable "application" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
  default     = "dev"
}

variable "origin_request" {
  type        = string
  description = "Lambda origin request"
}

variable "origin_domain_name" {
  type        = string
  description = "Origin domain nane"
}

variable "orgin_api_domain_name" {
  type = string
  description = "Api gateway name"
}
```

4. Add to the **main.tf** code that create Origin Access Identity

```terraform
resource "aws_cloudfront_origin_access_identity" "blog" {}
```

5. Add cloudfront distribution.

```
resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = var.origin_domain_name
    origin_id   = "origin-static-${var.environment}-${var.application}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.blog.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = var.orgin_api_domain_name
    origin_id   = "origin-ssr-${var.environment}-${var.application}"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled = true

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "origin-ssr-${var.environment}-${var.application}"

    forwarded_values {
      query_string = false
      headers      = ["Access-Control-Request-Headers", "Access-Control-Request-Method", "Origin"]

      cookies {
        forward = "none"
      }
    }

    compress               = true
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 10
    max_ttl                = 2592000
    
    lambda_function_association {
      event_type   = "origin-request"
      lambda_arn = var.origin_request
    }
  }

  ordered_cache_behavior {
    target_origin_id = "origin-ssr-${var.environment}-${var.application}"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    path_pattern           = "/_next/*"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 10
    max_ttl                = 2592000

    compress = true

    forwarded_values {
      query_string = false
      headers      = ["Access-Control-Request-Headers", "Access-Control-Request-Method", "Origin"]
      cookies {
        forward = "none"
      }
    }
  }

  ordered_cache_behavior {
    target_origin_id = "origin-static-${var.environment}-${var.application}"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    path_pattern           = "/static*"
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 10
    max_ttl                = 2592000

    compress = true

    forwarded_values {
      query_string = false
      headers      = ["Access-Control-Request-Headers", "Access-Control-Request-Method", "Origin"]
      cookies {
        forward = "none"
      }
    }
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  //web_acl_id = aws_wafv2_web_acl.waf_acl.arn

  tags = {
    Environment = var.environment
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


```

6. Try to verify what each section of this resource do **https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution**

7. In the **outputs.tf** file, create resource 

```terraform
output "origin_access_identity" {
  value = aws_cloudfront_origin_access_identity.blog.iam_arn
}
```

8. Add the module to the project. In the **main.tf** file in the **ssr** directory add
```terraform
module "cdn" {
  source             = "./modules/cdn"
  environment        = local.environment
  origin_domain_name = module.storage.origin_domain_name
  orgin_api_domain_name = trimprefix(trimsuffix(module.api.domain_name, "/${local.environment}"), "https://")
  application        = var.application
  origin_request     = module.lambda_at_edge.origin_request
  
  providers = {
    aws = aws.us-east-1
  }
}
```

9. Now you have to add permission to access s3 by cloudfront. To do so , go to **storage** module to **s3.tf** file and add 

```terraform
data "aws_iam_policy_document" "s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.origin_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [var.origin_access_identity]
    }
  }
}

resource "aws_s3_bucket_policy" "policy" {
  bucket = aws_s3_bucket.origin_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

```

10. In this directory modify **variables.tf** file to have

```terraform
variable "application" {
  type        = string
  description = "Application name"
}

variable "environment" {
  type        = string
  description = "Environment (e.g. `prod`, `dev`, `staging`)"
}

variable "origin_access_identity" {
  description = "Origin Access Identity"
}
```

11. Modify the module **storage**. In the **main.tf** file which is located in **ssr** directory change module to

```terraform
module "storage" {
  source                 = "./modules/storage"
  environment            = local.environment
  application            = var.application
  origin_access_identity = module.cdn.origin_access_identity
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

13. Go to AWS console and verify if cloudfront **https://console.aws.amazon.com/cloudfront/home?region=eu-west-1#distributions:** is created

14. Find the **Domain name** of your cloudfront, open in the browser eg d2tq2mqcgzlv60.cloudfront.net/dev/index , please remember to add **/dev/index** at the end. You can try also with the **/dev/about**
