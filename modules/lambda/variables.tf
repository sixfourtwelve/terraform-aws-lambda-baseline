variable "prefix" {
  type        = string
  description = "Prefix for naming resources"
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "memory_mb" {
  type    = number
  default = 512
}

variable "timeout_seconds" {
  type    = number
  default = 30
}

variable "zip_path" {
  type        = string
  description = "Local path to the zipped lambda code"
}

variable "iam_role_arn" {
  type        = string
  description = "ARN of the IAM role for the Lambda function"
}

variable "secret_arns" {
  type        = map(string)
  default     = {}
  description = "Map of secret ARNs to make available to the Lambda"
}

variable "environment_variables" {
  type        = map(string)
  default     = {}
  description = "Plain text env vars passed to the lambda"
}

variable "log_group_name" {
  type        = string
  description = "Name of the CloudWatch log group"
}

variable "tracing_mode" {
  type        = string
  default     = "PassThrough"
  description = "X-Ray tracing mode for the Lambda function: PassThrough or Active"
}

variable "reserved_concurrency" {
  type        = number
  default     = -1
  description = "Reserved concurrent executions. -1 means unreserved (uses account default). 0 disables the function."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource"
}