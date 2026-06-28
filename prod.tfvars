## Production Environment Configuration
## This file contains non-sensitive Terraform variables for prod environment

# Common variables
region      = "us-west-2"
environment = "prod"terraform_state_bucket = "gc-terraform-state-c8f7ewhysy5w"
# Networking
vpc_cidr          = "10.0.0.0/16"
public_subnets   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
private_subnets  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
database_subnets = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]
single_nat_gateway = false

# Database
db_name           = "goodconnex"
aurora_mode       = "provisioned"
instance_class    = "db.t4g.medium"
instance_count    = 2
enable_proxy      = true

# Elastic Beanstalk (Python Backend API)
instance_type      = "t3.medium"
min_size           = 2
max_size           = 6
app_port           = 8080
ssl_certificate_arn = "arn:aws:acm:us-west-2:ACCOUNT_ID:certificate/CERTIFICATE_ID"  # Replace with your cert ARN

# Tags
tags = {
  Environment = "prod"
  ManagedBy   = "terraform"
  Project     = "goodconnex"
}
