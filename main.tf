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

module "cloudwatch" {
  source = "./modules/cloudwatch"

  prefix             = local.prefix
  log_retention_days = var.log_retention_days
  tags               = local.common_tags
}

module "iam" {
  source = "./modules/iam"

  prefix                = local.prefix
  cloudwatch_log_group  = module.cloudwatch.log_group_arn
  extra_iam_policy_arns = var.extra_iam_policy_arns
  tags                  = local.common_tags
}

module "secret" {
  source = "./modules/secret"

  prefix       = local.prefix
  secret_value = var.secret_value
  iam_role_arn = module.iam.role_arn # IAM output feeds into secret policy
  tags         = local.common_tags
}

module "lambda" {
  source = "./modules/lambda"

  prefix          = local.prefix
  runtime         = var.lambda_runtime
  memory_mb       = var.lambda_memory_mb
  timeout_seconds = var.lambda_timeout_seconds
  zip_path        = var.lambda_zip_path
  iam_role_arn    = module.iam.role_arn
  secret_arn      = module.secret.secret_arn
  log_group_name  = module.cloudwatch.log_group_name
  tags            = local.common_tags
}
