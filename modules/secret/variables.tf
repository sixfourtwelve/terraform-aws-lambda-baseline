variable "prefix" {
  type        = string
  description = "Prefix for naming resources"
}

variable "secrets" {
  type = map(object({
    value       = string
    description = string
  }))
  default     = {}
  sensitive   = true
  description = "Map of secrets to create. Key becomes part of the secret name."
}

variable "iam_role_arn" {
  type        = string
  description = "ARN of the IAM role that will access these secrets"
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource"
}