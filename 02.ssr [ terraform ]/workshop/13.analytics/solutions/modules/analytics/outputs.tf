output "events_arn" {
  value = aws_kinesis_firehose_delivery_stream.events.arn
}

output "events_name" {
  value = aws_kinesis_firehose_delivery_stream.events.name
}

