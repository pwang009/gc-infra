module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.5"

  name = "${var.environment}-vpc"
  cidr = var.vpc_cidr

  azs              = ["${var.region}a", "${var.region}c"]
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.database_subnets

  # Automatically creates the group used by RDS
  create_database_subnet_group = true
  
  # NAT Gateway for App Tier to talk to CodeArtifact/Internet
  enable_nat_gateway = true
  single_nat_gateway = var.single_nat_gateway
  
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# S3 VPC Endpoint for cost-effective S3 access from private subnets
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
  
  route_table_ids = module.vpc.private_route_table_ids
  
  tags = {
    Name        = "${var.environment}-s3-endpoint"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}