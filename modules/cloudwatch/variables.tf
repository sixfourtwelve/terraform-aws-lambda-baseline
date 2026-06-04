variable "prefix" {
  type        = string
  description = "Prefix for naming resources"
}

variable "log_retention_days" {
  type    = number
  default = 30
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to every resource"
}