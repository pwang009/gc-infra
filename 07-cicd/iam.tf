resource "aws_iam_user" "github_deploy" {
  name = "github-deploy-${var.environment}"
}

resource "aws_iam_user_policy" "github_deploy" {
  name = "github-deploy-policy"
  user = aws_iam_user.github_deploy.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "codeartifact:GetAuthorizationToken",
          "codeartifact:GetRepositoryEndpoint",
          "codeartifact:ReadFromRepository",
          "codeartifact:PublishPackageVersion"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = "sts:GetServiceBearerToken"
        Resource = "*"
        Condition = {
          StringEquals = {
            "sts:AWSServiceName" = "codeartifact.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "elasticbeanstalk:CreateApplicationVersion",
          "elasticbeanstalk:UpdateEnvironment",
          "elasticbeanstalk:DescribeEnvironments"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::elasticbeanstalk-*/*",
          "arn:aws:s3:::gc-artifacts-${var.environment}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_access_key" "github_deploy" {
  user = aws_iam_user.github_deploy.name
}
