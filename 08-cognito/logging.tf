data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket  = var.terraform_state_bucket
    key     = "${var.environment}/01-network/terraform.tfstate"
    region  = "us-west-1"
    encrypt = true
  }
}

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.environment}/cognito"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.environment}-cognito-cloudtrail"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# CloudWatch Log Group for Lambda logs
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.environment}/cognito"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.environment}-cognito-lambda-logs"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
