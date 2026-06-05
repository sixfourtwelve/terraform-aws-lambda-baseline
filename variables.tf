variable "name" {
  type        = string
  description = "Base name for all resources, eg: payments-processor"
}

variable "environment" {
  type        = string
  description = "dev, staging, prod"
}

variable "lambda_runtime" {
  type    = string
  default = "python3.12"
}

variable "lambda_memory_mb" {
  type    = number
  default = 512
}

variable "lambda_timeout_seconds" {
  type    = number
  default = 30
}

variable "lambda_zip_path" {
  type        = string
  description = "Local path to the zipped lambda code"
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Plain text env vars passed to the lambda"
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

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "extra_iam_policy_arns" {
  type        = list(string)
  default     = []
  description = "Any extra AWS managed policies to attach"
}

variable "secret_recovery_window_days" {
  type        = number
  default     = 30
  description = "Days before a deleted secret can be permanently removed. Set to 0 in dev/test to allow immediate recreation."
}

variable "lambda_tracing_mode" {
  type        = string
  default     = "PassThrough"
  description = "X-Ray tracing mode for the Lambda function: PassThrough or Active"
}

variable "lambda_reserved_concurrency" {
  type        = number
  default     = -1
  description = "Reserved concurrent executions for the Lambda. -1 means unreserved (uses account default). 0 disables the function."
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags applied to every resource"
}