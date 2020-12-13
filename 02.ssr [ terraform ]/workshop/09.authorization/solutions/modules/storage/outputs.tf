output "blog_table_arn" {
  value = aws_dynamodb_table.blog.arn
}

output "blog_table_name" {
  value = aws_dynamodb_table.blog.id
}

output "origin_domain_name" {
  value = aws_s3_bucket.origin_bucket.bucket_regional_domain_name
}

output "origin_bucket_arn" {
  value = aws_s3_bucket.origin_bucket.arn
}

output "origin_bucket_name" {
  value = aws_s3_bucket.origin_bucket.id
}
