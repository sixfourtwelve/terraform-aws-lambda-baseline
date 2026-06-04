output "lambda_arn" {
  value = module.lambda.arn
}

output "lambda_name" {
  value = module.lambda.name
}

output "secret_arns" {
  value = module.secret.secret_arns
}

output "log_group_name" {
  value = module.cloudwatch.log_group_name
}

output "iam_role_arn" {
  value = module.iam.role_arn
}