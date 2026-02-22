# VPC Flow Logs to CloudWatch
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  name              = "/aws/vpc/flowlogs/${module.vpc.vpc_id}"
  retention_in_days = 14
}

resource "aws_iam_role" "vpc_flow_logs" {
  name = "${var.environment}-vpc-flow-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "vpc-flow-logs.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "vpc_flow_logs" {
  role       = aws_iam_role.vpc_flow_logs.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

resource "aws_flow_log" "vpc" {
  log_destination      = aws_cloudwatch_log_group.vpc_flow_logs.arn
  log_destination_type = "cloud-watch-logs"
  iam_role_arn         = aws_iam_role.vpc_flow_logs.arn
  vpc_id               = module.vpc.vpc_id
  traffic_type         = "ALL"
  tags = {
    Name        = "${var.environment}-vpc-flow-logs"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
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