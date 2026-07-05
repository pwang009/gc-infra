resource "aws_iam_user" "github_deployer" {
  name = "github-deployer"
}

resource "aws_iam_user_policy" "github_deployer" {
  name = "github-deployer-policy"
  user = aws_iam_user.github_deployer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "elasticbeanstalk:CreateApplicationVersion",
          "elasticbeanstalk:UpdateEnvironment",
          "elasticbeanstalk:DescribeEnvironments",
          "elasticbeanstalk:CreateEnvironment",
          "elasticbeanstalk:SwapEnvironmentCNAMEs"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "cloudformation:GetTemplate",
          "cloudformation:DescribeStacks",
          "cloudformation:UpdateStack",
          "cloudformation:DescribeStackResources",
          "cloudformation:DescribeStackResource"
        ]
        Resource = "arn:aws:cloudformation:*:*:stack/awseb-*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.deployment_bucket_name}",
          "arn:aws:s3:::${var.deployment_bucket_name}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole",
          "iam:GetRole"
        ]
        Resource = "arn:aws:iam::*:role/aws-elasticbeanstalk-*"
      }
    ]
  })
}

resource "aws_iam_user_policy" "github_deployer_eb_bucket" {
  name = "github-deployer-eb-bucket"
  user = aws_iam_user.github_deployer.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:PutBucketOwnershipControls",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectAcl",
          "s3:PutObjectAcl"
        ]
        Resource = [
          "arn:aws:s3:::elasticbeanstalk-*",
          "arn:aws:s3:::elasticbeanstalk-*/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:SuspendProcesses",
          "autoscaling:ResumeProcesses"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_access_key" "github_deployer" {
  user = aws_iam_user.github_deployer.name
}
