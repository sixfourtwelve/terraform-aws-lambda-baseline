resource "aws_cloudwatch_log_group" "this" {
  name              = "${var.prefix}-log-group"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}