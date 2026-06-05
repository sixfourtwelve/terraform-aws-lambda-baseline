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

variable "recovery_window_days" {
  type        = number
  default     = 30
  description = "Days before a deleted secret can be permanently removed. Set to 0 to disable recovery (useful in dev/test)."
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource"
}
