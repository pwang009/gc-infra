# Origin Access Control (OAC) for S3
resource "aws_cloudfront_origin_access_control" "react_app" {
  name                              = "oac-gc-app-${var.environment}"
  description                       = "OAC for React App S3 bucket (${var.environment})"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# CloudFront Distribution
resource "aws_cloudfront_distribution" "react_app" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "React App Frontend CDN (${var.environment})"
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  price_class         = var.price_class

  origin {
    domain_name              = aws_s3_bucket.react_app.bucket_regional_domain_name
    origin_id                = "S3-${aws_s3_bucket.react_app.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.react_app.id
  }

  default_cache_behavior {
    target_origin_id       = "S3-${aws_s3_bucket.react_app.id}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = false
      headers      = []

      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 86400    # 1 day
    max_ttl     = 31536000 # 1 year
  }

  # SPA Routing: Redirect 403 / 404 to index.html with HTTP 200 for React Router
  custom_error_response {
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  custom_error_response {
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
    error_caching_min_ttl = 10
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = merge(
    {
      Name        = "gc-app-cloudfront-${var.environment}"
      Environment = var.environment
      Project     = "goodconnex"
      Service     = "react-frontend"
      ManagedBy   = "terraform"
    },
    var.tags
  )
}
