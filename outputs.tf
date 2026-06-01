output "lambda_arn" {
  value = module.lambda.arn
}

output "lambda_name" {
  value = module.lambda.name
}

output "secret_arn" {
  value = module.secret.secret_arn
}

output "log_group_name" {
  value = module.cloudwatch.log_group_name
}

output "iam_role_arn" {
  value = module.iam.role_arn
}
