terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

locals {
  # One consistent name prefix for everything
  prefix = "${var.environment}-${var.name}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "secret" {
  source = "./modules/secret"

  prefix       = local.prefix
  secrets      = var.secrets
  iam_role_arn = module.iam.role_arn
  tags         = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  prefix                = local.prefix
  cloudwatch_log_group  = module.cloudwatch.log_group_arn
  secret_arns           = values(module.secret.secret_arns) # map => list
  extra_iam_policy_arns = var.extra_iam_policy_arns
  tags                  = local.common_tags
}

module "lambda" {
  source = "./modules/lambda"

  prefix                = local.prefix
  runtime               = var.lambda_runtime
  memory_mb             = var.lambda_memory_mb
  timeout_seconds       = var.lambda_timeout_seconds
  zip_path              = var.lambda_zip_path
  iam_role_arn          = module.iam.role_arn
  secret_arns           = module.secret.secret_arns
  environment_variables = var.environment_variables
  log_group_name        = module.cloudwatch.log_group_name
  tags                  = local.common_tags
}
