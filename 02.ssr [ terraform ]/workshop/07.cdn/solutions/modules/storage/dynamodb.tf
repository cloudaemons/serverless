resource "aws_dynamodb_table" "blog" {
  name         = "${var.environment}-${var.application}-blog"
  hash_key     = "id"
  billing_mode = "PAY_PER_REQUEST"
  attribute {
    name = "id"
    type = "S"
  }
}
