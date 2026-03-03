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