## Development Environment Configuration
## This file contains non-sensitive Terraform variables for dev environment

# Common variables
aws_region      = "us-west-2"
region          = "us-west-2"
environment     = "dev"
terraform_state_bucket = "gc-terraform-state-c8f7ewhysy5w"

# Networking
vpc_cidr          = "10.100.0.0/24"
public_subnets   = ["10.100.0.0/27", "10.100.0.32/27"]
private_subnets  = ["10.100.0.64/26"]
database_subnets = ["10.100.0.224/28", "10.100.0.240/28"]
single_nat_gateway = true

# Database
db_name           = "goodconnex"
aurora_mode       = "serverless"
instance_class    = "db.serverless"
instance_count    = 1
enable_proxy      = false

# Elastic Beanstalk (Python Backend API)
instance_type      = "t3.micro"
min_size           = 1
max_size           = 2
app_port           = 8080
ssl_certificate_arn = "arn:aws:acm:us-west-2:339087217430:certificate/1354a63d-74aa-4b0e-9b43-872457f0250c"

# Tags
tags = {
  Environment = "dev"
  ManagedBy   = "terraform"
  Project     = "goodconnex"
}
