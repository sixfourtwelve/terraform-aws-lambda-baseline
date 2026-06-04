variable "prefix" {
  type        = string
  description = "Prefix for naming resources"
}

variable "cloudwatch_log_group" {
  type        = string
  description = "ARN of the CloudWatch log group"
}

variable "secret_arns" {
  type        = list(string)
  default     = []
  description = "List of secret ARNs to grant access to"
}

variable "extra_iam_policy_arns" {
  type        = list(string)
  default     = []
  description = "Any extra AWS managed policies to attach"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource"
}