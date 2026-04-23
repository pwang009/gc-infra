resource "aws_iam_policy" "eb_fileupload_access" {
  name        = "elasticbeanstalk-fileupload-access-policy"
  description = "Policy to allow Beanstalk EC2 instances full access to fileupload S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.fileupload.arn,
          "${aws_s3_bucket.fileupload.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketVersioning",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.fileupload.arn
      }
    ]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "eb_fileupload_attachment" {
  role       = "aws-elasticbeanstalk-ec2-role"
  policy_arn = aws_iam_policy.eb_fileupload_access.arn
}
