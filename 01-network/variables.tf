variable "region" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "public_subnets" {
  type = list(string)
}

variable "private_subnets" {
  type = list(string)
}

variable "database_subnets" {
  type = list(string)
}

variable "environment" {
  description = "Deployment environment (dev, prod)"
  type        = string
}

variable "single_nat_gateway" {
  description = "Should be true for dev (save costs) and false for prod (high availability)"
  type        = bool
}

# Add these if you are ready to deploy the VPN section
# variable "vpn_server_cert_arn" { type = string }
# variable "vpn_client_ca_arn"   { type = string }