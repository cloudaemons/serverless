resource "aws_sns_topic" "notifications" {
  name = "analytics-notifications-${var.environment}-${var.application}"
}
