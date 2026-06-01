variable "prefix" {
  description = "A consistent name prefix for all resources in this module"
  type        = string
}

variable "tags" {
  description = "Tags to apply to the secret"
  type        = map(string)
  default     = {}
}

variable "secrets" {
  type = map(object({
    value       = string
    description = string
  }))
  sensitive = true
}

variable "iam_role_arn" {
  description = "ARN of IAM role to allow access to this secret"
  type        = string
}
