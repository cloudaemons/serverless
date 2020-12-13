# 08. Web Application Firewall

## LAB PURPOSE

Create Web Application Firewall

## DEFINITIONS
----

### AWS WAF

AWS WAF is a web application firewall that helps protect your web applications or APIs against common web exploits that may affect availability, compromise security, or consume excessive resources. AWS WAF gives you control over how traffic reaches your applications by enabling you to create security rules that block common attack patterns, such as SQL injection or cross-site scripting, and rules that filter out specific traffic patterns you define

## STEPS

### CREATE WAF

1. Go to  **cdn** directory and create  **waf.tf** file

2. Add to the file resource responsible for geo restriction

```terraform

resource "aws_wafv2_web_acl" "waf_acl" {
  name  = "webacl-${var.environment}-${var.application}"
  scope = "CLOUDFRONT"

  default_action {
    block {}
  }

  rule {
    // ACCESS TO ALL ASSETS FROM EU
    name     = "geo-whitelist-${var.environment}-${var.application}"
    priority = 0

    action {
      allow {}
    }

    statement {
      geo_match_statement {
        country_codes = [
          "BE",
          "BG",
          "CZ",
          "DK",
          "DE",
          "EE",
          "IE",
          "GR",
          "ES",
          "FR",
          "HR",
          "IT",
          "CY",
          "LV",
          "LT",
          "LU",
          "HU",
          "MT",
          "NL",
          "AT",
          "PL",
          "PT",
          "RO",
          "SI",
          "SK",
          "FI",
          "SE"
        ]
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "rule-geo-whitelist-${var.environment}-${var.application}"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "acl-allow-geo-${var.environment}-${var.application}"
    sampled_requests_enabled   = false
  }

}
```

3. Go to **main.tf** file and uncomment the code responsible for attaching the waf to the cf

```
web_acl_id = aws_wafv2_web_acl.waf_acl.arn
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

5. Try to play with this resource, for example remove from the list the country where are you located , deploy the infrastructure, and see what's happend




