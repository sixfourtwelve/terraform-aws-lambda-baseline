terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Point every relevant service at the local MiniStack container.
# MINISTACK_ENDPOINT defaults to http://localhost:4566 but can be
# overridden (e.g. in CI: http://ministack:4566).
locals {
  endpoint = var.ministack_endpoint
}

provider "aws" {
  access_key = "test"
  secret_key = "test"
  region     = "us-east-1"

  # Not a real AWS account — skip all credential/account checks.
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    iam            = local.endpoint
    lambda         = local.endpoint
    secretsmanager = local.endpoint
    cloudwatchlogs = local.endpoint
  }
}
