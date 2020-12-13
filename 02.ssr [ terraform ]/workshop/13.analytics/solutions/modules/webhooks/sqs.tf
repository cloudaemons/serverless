resource "aws_sqs_queue" "queue" {
  name                              = "webhooks-${var.name}-${var.environment}-${var.application}"
  delay_seconds                     = var.delay_seconds
  max_message_size                  = var.max_message_size
  message_retention_seconds         = var.message_retention_seconds
  receive_wait_time_seconds         = var.receive_wait_time_seconds
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.maxReceiveCount
  })
}

resource "aws_sqs_queue" "dlq" {
  name                              = "webhooks-${var.name}-dlq-${var.environment}-${var.application}"
  kms_master_key_id                 = "alias/aws/sqs"
  kms_data_key_reuse_period_seconds = 300
}
