# Elastic Beanstalk Module - Development Configuration
aws_region = "us-west-2"
environment = "dev"
terraform_state_bucket = "gc-terraform-state-c8f7ewhysy5w"
instance_type = "t3.micro"
min_size = 1
max_size = 2
app_port = 8080
ssl_certificate_arn = "arn:aws:acm:us-west-2:339087217430:certificate/1354a63d-74aa-4b0e-9b43-872457f0250c"
