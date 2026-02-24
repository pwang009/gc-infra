variable "region" {
  type = string
}

variable "environment" {
  type = string
}

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "app_s3_bucket" {
  description = "S3 bucket name for application JAR files"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = "gconnex-ec2"
}
