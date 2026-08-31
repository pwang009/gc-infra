variable "aws_region" {
  description = "AWS region for S3 bucket"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name for the React application (e.g., app.dev.goodconnex.com)"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate in us-east-1 for CloudFront"
  type        = string
}

variable "bucket_name" {
  description = "Custom S3 bucket name (optional, defaults to gc-app-{environment}-{account_id})"
  type        = string
  default     = ""
}

variable "price_class" {
  description = "CloudFront price class"
  type        = string
  default     = "PriceClass_100"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

