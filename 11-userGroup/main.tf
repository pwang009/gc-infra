terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

resource "aws_iam_group" "api_testers" {
  name = "API-Testers"
  path = "/"
}

resource "aws_iam_policy" "api_testers_cloudwatch_logs" {
  name        = "${var.environment}-api-testers-cloudwatch-logs"
  description = "Allow API-Testers to view CloudWatch metrics and Cognito/Beanstalk log streams"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListLogGroups"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "ReadCloudWatchMetrics"
        Effect = "Allow"
        Action = [
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      },
      {
        Sid    = "ReadCognitoAndBeanstalkLogs"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogStreams",
          "logs:FilterLogEvents",
          "logs:GetLogEvents",
          "logs:GetQueryResults",
          "logs:StartQuery",
          "logs:StopQuery"
        ]
        Resource = [
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*/cognito",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*/cognito:*",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/elasticbeanstalk/gc-api-*/*",
          "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/elasticbeanstalk/gc-api-*/*:*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "api_testers_ssm_port_forwarding" {
  name        = "${var.environment}-api-testers-ssm-port-forwarding"
  description = "Allow API-Testers to start SSM port-forwarding sessions for RDS access"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSsmSessionManagement"
        Effect = "Allow"
        Action = [
          "ssm:DescribeSessions",
          "ssm:ResumeSession",
          "ssm:TerminateSession"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowStartPortForwardingSession"
        Effect = "Allow"
        Action = [
          "ssm:StartSession"
        ]
        Resource = [
          "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
          "arn:aws:ssm:${var.aws_region}::document/AWS-StartPortForwardingSessionToRemoteHost"
        ]
      },
      {
        Sid    = "AllowDescribeInstancesForTargetSelection"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "api_testers_logs" {
  group      = aws_iam_group.api_testers.name
  policy_arn = aws_iam_policy.api_testers_cloudwatch_logs.arn
}

resource "aws_iam_group_policy_attachment" "api_testers_ssm" {
  group      = aws_iam_group.api_testers.name
  policy_arn = aws_iam_policy.api_testers_ssm_port_forwarding.arn
}

resource "aws_iam_user_group_membership" "pwang006_api_testers" {
  user  = "pwang006"
  groups = [aws_iam_group.api_testers.name]
}
