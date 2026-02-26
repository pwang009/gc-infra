variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "xray_sampling_rate" {
  description = "X-Ray sampling rate (0.0 to 1.0). 0.1 = 10%, 1.0 = 100%"
  type        = number
  default     = 0.1
  validation {
    condition     = var.xray_sampling_rate >= 0 && var.xray_sampling_rate <= 1
    error_message = "xray_sampling_rate must be between 0 and 1."
  }
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days for X-Ray insights"
  type        = number
  default     = 30
}
