resource "aws_lambda_function" "this" {
  function_name = "${var.prefix}-lambda"
  runtime       = var.runtime
  handler       = "index.handler"
  memory_size   = var.memory_mb
  timeout       = var.timeout_seconds
  role          = var.iam_role_arn

  filename         = var.zip_path
  source_code_hash = filebase64sha256(var.zip_path)

  environment {
    variables = {
      SECRET_ARN     = var.secret_arn
      LOG_GROUP_NAME = var.log_group_name
    }
  }

  tags = var.tags
}
