provider "aws" {
  region = var.aws_region
}

# X-Ray Sampling Rule for tracing
resource "aws_xray_sampling_rule" "gc_api_sampling" {
  rule_name      = "${var.environment}-gc-api-sampling"
  priority       = 1
  version        = 1
  reservoir_size = 1
  fixed_rate     = var.xray_sampling_rate
  url_path       = "*"
  host           = "*"
  http_method    = "*"
  service_type   = "*"
  service_name   = "*"
  resource_arn   = "*"

  attributes = {
    Environment = var.environment
    Application = "gc-api"
  }

  tags = {
    Name        = "${var.environment}-gc-api-sampling"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# X-Ray Group for filtering/organizing traces
resource "aws_xray_group" "gc_api_group" {
  group_name        = "${var.environment}-gc-api-traces"
  filter_expression = "service(\"gc-api\")"
  insights_configuration {
    insights_enabled      = true
    notifications_enabled = true
  }

  tags = {
    Name        = "${var.environment}-gc-api-traces"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# CloudWatch Log Group for X-Ray insights
resource "aws_cloudwatch_log_group" "xray_insights" {
  name              = "/aws/x-ray/${var.environment}/insights"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.environment}-xray-insights"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# X-Ray Encryption Config (optional but recommended)
resource "aws_xray_encryption_config" "gc_api" {
  type       = "NONE" # Use "KMS" if you want to encrypt with a KMS key
  key_id     = null   # Provide KMS key ID if type is "KMS"
  depends_on = [aws_xray_sampling_rule.gc_api_sampling]
}
