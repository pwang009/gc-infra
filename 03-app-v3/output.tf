output "s3_bucket_name" {
  description = "Name of the S3 bucket hosting the React frontend"
  value       = aws_s3_bucket.react_app.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.react_app.arn
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.react_app.id
}

output "cloudfront_distribution_arn" {
  description = "ARN of the CloudFront distribution"
  value       = aws_cloudfront_distribution.react_app.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront distribution domain name (points GoDaddy CNAME here)"
  value       = aws_cloudfront_distribution.react_app.domain_name
}

output "domain_name" {
  description = "Custom domain name for the React app"
  value       = var.domain_name
}

output "godaddy_cname_instructions" {
  description = "GoDaddy DNS Configuration Instructions"
  value       = "In GoDaddy DNS for goodconnex.com, add a CNAME record: Host = 'app.dev', Points to = '${aws_cloudfront_distribution.react_app.domain_name}'"
}


