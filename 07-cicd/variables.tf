variable "region" {
  type = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  type = string
}

variable "terraform_state_bucket" {
  description = "S3 bucket for Terraform remote state"
  type        = string
}

variable "deployment_bucket_name" {
  description = "S3 bucket used for deployment artifacts"
  type        = string
  default     = "gc-app-deployments-c8f7ewhysy5w"
}
