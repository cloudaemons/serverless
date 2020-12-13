output "origin_access_identity" {
  value = aws_cloudfront_origin_access_identity.blog.iam_arn
}

