# Integration test fixture — calls the root module against MiniStack.
#
# Exercises:
#   • CloudWatch log group with custom retention
#   • Two Secrets Manager secrets (secret ARNs injected as env vars)
#   • Least-privilege IAM role + policies
#   • Lambda function wired to all of the above
module "lambda_baseline" {
  source = "../.."

  name        = "test"
  environment = "ministack"

  lambda_zip_path        = var.lambda_zip_path
  lambda_runtime         = "python3.12"
  lambda_memory_mb       = 128
  lambda_timeout_seconds = 10

  # Set to 0 so terraform destroy can immediately recreate with same name.
  secret_recovery_window_days = 0

  secrets = {
    api_key = {
      value       = "super-secret-api-key"
      description = "Test API key secret"
    }
    db_password = {
      value       = "super-secret-db-password"
      description = "Test DB password secret"
    }
  }

  environment_variables = {
    LOG_LEVEL = "DEBUG"
  }

  log_retention_days = 7

  tags = {
    Test = "true"
  }
}
