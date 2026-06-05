locals {
  secret_arn_env_vars = {
    for key, arn in var.secret_arns : "${upper(key)}_SECRET_ARN" => arn
  }

  all_env_vars = merge(var.environment_variables, local.secret_arn_env_vars)
}

resource "aws_lambda_function" "this" {
  function_name = "${var.prefix}-lambda"
  runtime       = var.runtime
  handler       = "index.handler"
  memory_size   = var.memory_mb
  timeout       = var.timeout_seconds
  role          = var.iam_role_arn

  filename         = var.zip_path
  source_code_hash = filebase64sha256(var.zip_path)

  reserved_concurrent_executions = var.reserved_concurrency

  tracing_config {
    mode = var.tracing_mode
  }

  logging_config {
    log_format = "JSON"
    log_group  = var.log_group_name
  }

  environment {
    variables = local.all_env_vars
  }

  tags = var.tags
}
