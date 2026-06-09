variable "ministack_endpoint" {
  type        = string
  default     = "http://localhost:4566"
  description = "MiniStack endpoint URL. Override in CI if the container is on a different host."
}

variable "lambda_zip_path" {
  type        = string
  description = "Path to the pre-built fixture Lambda zip. Built by the test script."
}
