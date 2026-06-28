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

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for file uploads"
}
