resource "aws_s3_bucket" "events" {
  bucket = "events-${var.environment}-${var.application}"
  acl    = "private"

  tags = {
    Name        = "events-${var.environment}-${var.application}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket" "query_output" {
  bucket = "query-output-${var.environment}-${var.application}"
  acl    = "private"

  tags = {
    Name        = "query-output-${var.environment}-${var.application}"
    Environment = var.environment
  }
}
