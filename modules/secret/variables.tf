variable "prefix" {
  description = "A consistent name prefix for all resources in this module"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the secret"
  type        = map(string)
  default     = {}
}

variable "secret_value" {
  description = "The value to store in the secret"
  type        = string
  sensitive   = true
}

variable "iam_role_arn" {
  description = "ARN of IAM role to allow access to this secret"
  type        = string
}
