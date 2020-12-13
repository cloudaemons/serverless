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