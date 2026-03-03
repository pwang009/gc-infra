# Kinesis Firehose for WAF logs to S3
resource "aws_kinesis_firehose_delivery_stream" "waf_logs_firehose" {
  name        = "aws-waf-logs-firehose-${var.environment}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn            = aws_iam_role.firehose_role.arn
    bucket_arn          = aws_s3_bucket.alb_access_logs.arn
    prefix              = "waf-logs/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "waf-logs-errors/"
  }
}

# IAM role for Firehose
resource "aws_iam_role" "firehose_role" {
  name = "firehose-waf-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# IAM policy for Firehose to write to S3
resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose-waf-policy-${var.environment}"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.alb_access_logs.arn,
          "${aws_s3_bucket.alb_access_logs.arn}/*"
        ]
      }
    ]
  })
}

# WAF logging configuration
resource "aws_wafv2_web_acl_logging_configuration" "beanstalk_waf_logging" {
  resource_arn            = aws_wafv2_web_acl.beanstalk_waf.arn
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs_firehose.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}