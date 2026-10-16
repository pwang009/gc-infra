variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name (e.g. dev, prod)"
  type        = string
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  type        = string
}

variable "app_name" {
  description = "Elastic Beanstalk application name"
  type        = string
  default     = "gc-api"
}

variable "env_name" {
  description = "Elastic Beanstalk environment name override"
  type        = string
  default     = null
}

variable "auth_mode" {
  description = "Authentication mode (e.g., cognito)"
  type        = string
  default     = "cognito"
}

variable "cognito_region" {
  description = "AWS region for Cognito user pool"
  type        = string
  default     = "us-west-2"
}

variable "cors_allow_origins" {
  description = "Comma-separated list of allowed CORS origins"
  type        = string
  default     = "https://www.goodconnex.com,https://goodconnex.com,https://app.goodconnex.com,https://wp.goodconnex.com"
}

variable "db_name" {
  description = "Database name override (defaults to 02-db remote state output)"
  type        = string
  default     = null
}

variable "db_user" {
  description = "Database username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Database password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "db_url" {
  description = "Database host URL override (defaults to 02-db remote state proxy or cluster endpoint)"
  type        = string
  default     = null
}

variable "image_moderation" {
  description = "Image moderation service (e.g. rekognition)"
  type        = string
  default     = "rekognition"
}

variable "log_cloudwatch_enabled" {
  description = "Enable CloudWatch logging"
  type        = string
  default     = "true"
}

variable "log_cloudwatch_group" {
  description = "CloudWatch log group name for application logs"
  type        = string
  default     = null
}

variable "log_cloudwatch_region" {
  description = "CloudWatch logging AWS region"
  type        = string
  default     = null
}

variable "log_format" {
  description = "Logging format (e.g. json, text)"
  type        = string
  default     = "json"
}

variable "log_http_bodies" {
  description = "Whether to log HTTP request and response bodies"
  type        = string
  default     = "true"
}

variable "log_http_body_max_bytes" {
  description = "Maximum bytes to log for HTTP bodies"
  type        = string
  default     = "8192"
}

variable "log_level" {
  description = "Application log level"
  type        = string
  default     = "INFO"
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "use_s3_media_remote_state" {
  description = "Whether to query 10-s3 remote state file for media bucket outputs"
  type        = bool
  default     = true
}

variable "media_backend" {
  description = "Media backend storage provider (e.g. s3)"
  type        = string
  default     = "s3"
}

variable "media_s3_bucket" {
  description = "S3 bucket for media storage override (defaults to 10-s3 remote state output)"
  type        = string
  default     = null
}

variable "media_s3_region" {
  description = "S3 bucket region for media storage override (defaults to 10-s3 remote state output)"
  type        = string
  default     = null
}

variable "otp_owner" {
  description = "OTP owner provider (e.g. cognito)"
  type        = string
  default     = "cognito"
}

variable "app_port" {
  description = "Application listening port"
  type        = string
  default     = "8080"
}

variable "push_delivery" {
  description = "Push notification delivery service (e.g. expo)"
  type        = string
  default     = "expo"
}

variable "python_path" {
  description = "Python path for Elastic Beanstalk environment"
  type        = string
  default     = "/var/app/venv/staging-LQM1lest/bin"
}

variable "revenuecat_api_key" {
  description = "RevenueCat API Key"
  type        = string
  sensitive   = true
  default     = ""
}

variable "revenuecat_webhook_secret" {
  description = "RevenueCat Webhook Secret"
  type        = string
  sensitive   = true
  default     = ""
}

variable "slots_dev_grant" {
  description = "Slots dev grant flag"
  type        = string
  default     = "false"
}
