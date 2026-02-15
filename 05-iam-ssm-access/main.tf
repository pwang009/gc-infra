provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "ssm_access" {
  name        = "${var.environment}-ssm-access-policy"
  description = "Policy to allow SSM access to ${var.environment} EC2 instances from specific IPs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSSMStartSession"
        Effect = "Allow"
        Action = [
          "ssm:StartSession"
        ]
        Resource = [
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/*"
        ]
        Condition = {
          StringEquals = {
            "ssm:resourceTag/Environment" = var.environment
          }
          IpAddress = {
            "aws:SourceIp" = var.allowed_source_ips
          }
        }
      },
      {
        Sid    = "AllowSSMSessionManagement"
        Effect = "Allow"
        Action = [
          "ssm:TerminateSession",
          "ssm:ResumeSession",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowListInstances"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_group" "ssm_users" {
  name = "${var.environment}-ssm-users"
}

resource "aws_iam_group_policy_attachment" "ssm_access" {
  group      = aws_iam_group.ssm_users.name
  policy_arn = aws_iam_policy.ssm_access.arn
}
