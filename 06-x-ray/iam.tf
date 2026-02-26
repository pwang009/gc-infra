# IAM Policy for X-Ray write access
resource "aws_iam_policy" "xray_write" {
  name        = "${var.environment}-xray-write-policy"
  description = "Policy to allow EC2 instances to write traces to X-Ray"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:log-group:/aws/x-ray/${var.environment}/*"
      }
    ]
  })

  tags = {
    Name        = "${var.environment}-xray-write"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

output "xray_policy_arn" {
  description = "ARN of the X-Ray write policy"
  value       = aws_iam_policy.xray_write.arn
}
