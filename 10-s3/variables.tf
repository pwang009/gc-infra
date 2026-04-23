variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "bucket_name" {
  type        = string
  description = "Name of the S3 bucket for file uploads"
}
