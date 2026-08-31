variable "region" {
  description = "AWS region for Lightsail instance"
  type        = string
  default     = "us-west-2"
}

variable "availability_zone" {
  description = "Availability Zone for the Lightsail instance (e.g., us-west-2a)"
  type        = string
  default     = "us-west-2a"
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "instance_name" {
  description = "Name of the Lightsail WordPress instance"
  type        = string
  default     = "gc-wordpress"
}

variable "blueprint_id" {
  description = "Blueprint ID for the Lightsail instance (wordpress_ls_1_0 is AWS-native Amazon Linux blueprint, wordpress is legacy Bitnami)"
  type        = string
  default     = "wordpress_ls_1_0"
}

variable "bundle_id" {
  description = "Lightsail instance plan / bundle ID (e.g., nano_3_0, micro_3_0, small_3_0, medium_3_0, large_3_0)"
  type        = string
  default     = "small_3_0"
}

variable "key_pair_name" {
  description = "Optional custom Lightsail SSH key pair name"
  type        = string
  default     = null
}

variable "allowed_ssh_cidrs" {
  description = "List of CIDR blocks allowed to connect via SSH (port 22)"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "domain_name" {
  description = "Custom domain for the CloudFront distribution (e.g. wp.goodconnex.com)"
  type        = string
  default     = "wp.goodconnex.com"
}

variable "acm_certificate_arn" {
  description = "ACM Certificate ARN in us-east-1 for CloudFront"
  type        = string
  default     = "arn:aws:acm:us-east-1:339087217430:certificate/4daf92dd-8152-4a14-9079-ea86dc6247fb"
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
  default     = {}
}
