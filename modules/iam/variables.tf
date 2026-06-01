variable "prefix" {
  description = "A consistent name prefix for all resources in this module"
  type        = string
}

variable "cloudwatch_log_group" {
  description = "ARN of CloudWatch log group to allow access to from IAM role"
  type        = string
}

variable "tags" {
  description = "Tags to apply to IAM role and policies"
  type        = map(string)
  default     = {}
}

variable "extra_iam_policy_arns" {
  type        = list(string)
  default     = []
  description = "Any extra AWS managed policies to attach"
}

variable "secret_arns" {
  type        = list(string)
  default     = []
  description = "ARNs of secrets to allow access to from IAM role"
}
