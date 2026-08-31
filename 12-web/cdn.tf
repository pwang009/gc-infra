# AWS CloudFront Distribution (CDN) in front of Lightsail WordPress
# Uses the ACM Certificate in us-east-1

resource "aws_cloudfront_distribution" "wordpress" {
  enabled             = true
  is_ipv6_enabled     = true
  comment             = "${var.instance_name} CloudFront CDN"
  aliases             = [var.domain_name]
  price_class         = "PriceClass_100" # US, Canada & Europe (cost-effective)

  origin {
    # CloudFront requires an FQDN domain name, not a raw IP address
    domain_name = var.region == "us-east-1" ? format("ec2-%s.compute-1.amazonaws.com", replace(aws_lightsail_static_ip.wordpress.ip_address, ".", "-")) : format("ec2-%s.%s.compute.amazonaws.com", replace(aws_lightsail_static_ip.wordpress.ip_address, ".", "-"), var.region)
    origin_id   = "lightsail-${aws_lightsail_instance.wordpress.name}"

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only" # Lightsail origin listens on HTTP 80
      origin_ssl_protocols     = ["TLSv1.2"]
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
    }
  }

  # Default Cache Behavior for WordPress
  default_cache_behavior {
    target_origin_id       = "lightsail-${aws_lightsail_instance.wordpress.name}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["Host", "Authorization", "CloudFront-Forwarded-Proto"]

      cookies {
        forward           = "whitelist"
        whitelisted_names = ["comment_author_*", "comment_author_email_*", "comment_author_url_*", "wordpress_*", "wordpress_logged_in_*", "wordpress_test_cookie", "wp-settings-*"]
      }
    }

    min_ttl     = 0
    default_ttl = 300
    max_ttl     = 86400
  }

  # Bypass cache for WordPress Admin
  ordered_cache_behavior {
    path_pattern           = "wp-admin/*"
    target_origin_id       = "lightsail-${aws_lightsail_instance.wordpress.name}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # Bypass cache for WordPress Login
  ordered_cache_behavior {
    path_pattern           = "wp-login.php"
    target_origin_id       = "lightsail-${aws_lightsail_instance.wordpress.name}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  # Bypass cache for REST API
  ordered_cache_behavior {
    path_pattern           = "wp-json/*"
    target_origin_id       = "lightsail-${aws_lightsail_instance.wordpress.name}"
    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]
    compress               = true

    forwarded_values {
      query_string = true
      headers      = ["*"]
      cookies {
        forward = "all"
      }
    }

    min_ttl     = 0
    default_ttl = 0
    max_ttl     = 0
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  tags = merge(
    {
      Name        = "${var.instance_name}-cloudfront"
      Environment = var.environment
      Project     = "goodconnex"
      Service     = "marketing-wordpress"
    },
    var.tags
  )
}
