variable "prefix" {
  description = "A consistent name prefix for all resources in this module"
  type        = string
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
}

variable "tags" {
  description = "Tags to apply to the CloudWatch log group"
  type        = map(string)
  default     = {}
}

