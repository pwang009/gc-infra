# Network Module - Development Configuration
region          = "us-west-2"
environment     = "dev"
vpc_cidr        = "10.100.0.0/24"
public_subnets = ["10.100.0.0/27", "10.100.0.32/27"]
private_subnets = ["10.100.0.64/26"]
database_subnets = ["10.100.0.224/28", "10.100.0.240/28"]
single_nat_gateway = true
