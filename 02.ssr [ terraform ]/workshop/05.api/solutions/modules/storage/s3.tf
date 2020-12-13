resource "aws_s3_bucket" "origin_bucket" {
  acl = "private"

  tags = {
    Application = var.application
    Environment = var.environment
    Name        = "Origin bucket"
  }
}
