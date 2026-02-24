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
          "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
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

# IAM role for EC2 instance to allow SSM
resource "aws_iam_role" "ssm_ec2_role" {
  name = "${var.environment}-ssm-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
  role       = aws_iam_role.ssm_ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_ec2_profile" {
  name = "${var.environment}-ssm-ec2-profile"
  role = aws_iam_role.ssm_ec2_role.name
}