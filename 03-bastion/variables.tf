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

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "allowed_source_ips" {
  description = "List of source IP CIDRs allowed to reach the bastion on management ports"
  type        = list(string)
  default     = []
}