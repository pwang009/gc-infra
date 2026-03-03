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

variable "certificate_arn" {
  description = "ARN of the ACM certificate for VPN domain (vpn.abc.com)"
  type        = string
}