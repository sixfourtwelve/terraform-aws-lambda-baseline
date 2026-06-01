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
  prefix = "${var.environment}-${var.name}"

  common_tags = merge(var.tags, {
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

module "cloudwatch" {
  source = "./modules/cloudwatch"
}

module "iam" {
  source = "./modules/iam"
}

module "secret" {
  source = "./modules/secret"
}

module "lambda" {
  source = "./modules/lambda"
}
