locals {
  bucket_name = var.bucket_name != "" ? var.bucket_name : "gc-app-${var.environment}-${data.aws_caller_identity.current.account_id}"
}

data "aws_caller_identity" "current" {}

# S3 Bucket for React Application
resource "aws_s3_bucket" "react_app" {
  bucket = local.bucket_name

  tags = merge(
    {
      Name        = local.bucket_name
      Environment = var.environment
      Project     = "goodconnex"
      Service     = "react-frontend"
      ManagedBy   = "terraform"
    },
    var.tags
  )
}

# S3 Bucket Public Access Block (CloudFront OAC uses private access)
resource "aws_s3_bucket_public_access_block" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "react_app" {
  bucket = aws_s3_bucket.react_app.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Policy allowing CloudFront OAC read access
resource "aws_s3_bucket_policy" "react_app" {
  bucket     = aws_s3_bucket.react_app.id
  depends_on = [aws_s3_bucket_public_access_block.react_app]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipalReadOnly"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.react_app.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.react_app.arn
          }
        }
      }
    ]
  })
}
