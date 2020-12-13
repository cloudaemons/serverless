resource "aws_cloudfront_origin_access_identity" "blog" {}

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

