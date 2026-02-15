variable "region" {
  description = "AWS region"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
}

variable "allowed_source_ips" {
  description = "List of IP addresses allowed to access EC2 via SSM"
  type        = list(string)
}
