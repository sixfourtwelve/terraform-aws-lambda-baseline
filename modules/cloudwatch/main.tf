resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.prefix}-lambda"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}