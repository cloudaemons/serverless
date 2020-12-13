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
