output "lambda_arn" {
  value = module.lambda_baseline.lambda_arn
}

output "lambda_name" {
  value = module.lambda_baseline.lambda_name
}

output "iam_role_arn" {
  value = module.lambda_baseline.iam_role_arn
}

output "log_group_name" {
  value = module.lambda_baseline.log_group_name
}

output "secret_arns" {
  value = module.lambda_baseline.secret_arns
}
