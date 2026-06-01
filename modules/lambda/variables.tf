variable "prefix" {
  type        = string
  description = "Env prefix eg dev, staging or prod"
}

variable "runtime" {
  type        = string
  description = "Lambda runtime eg nodejs18.x"
}

variable "memory_mb" {
  type        = number
  description = "Lambda memory in MB"
}

variable "timeout_seconds" {
  type        = number
  description = "Lambda timeout in seconds"
}

variable "zip_path" {
  type        = string
  description = "Path to lambda zip file"
}

variable "iam_role_arn" {
  type        = string
  description = "ARN of IAM role for lambda to assume"
}

variable "secret_arn" {
  type        = string
  description = "ARN of secret to access from lambda"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to lambda"
  default     = {}
}

variable "log_group_name" {
  type        = string
  description = "Name of CloudWatch log group to allow access to from IAM role"
}
