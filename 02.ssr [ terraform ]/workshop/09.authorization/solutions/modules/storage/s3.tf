resource "aws_s3_bucket" "origin_bucket" {
  acl = "private"

  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "Origin bucket"
  }
}

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
