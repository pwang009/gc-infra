
variable "instance_type" {
  description = "EC2 instance type for Beanstalk ASG"
  type        = string
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform remote state"
  type        = string
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "app_port" {
  description = "Port for the Spring Boot application"
  type        = number
  default     = 8080
}

variable "ssl_certificate_arn" {
  description = "ARN of the SSL certificate for HTTPS"
  type        = string
}
