output "instance_id" {
  description = "Lightsail instance ID"
  value       = aws_lightsail_instance.wordpress.id
}

output "instance_arn" {
  description = "Lightsail instance ARN"
  value       = aws_lightsail_instance.wordpress.arn
}

output "instance_name" {
  description = "Lightsail instance name"
  value       = aws_lightsail_instance.wordpress.name
}

output "blueprint_id" {
  description = "Blueprint ID used for the instance"
  value       = aws_lightsail_instance.wordpress.blueprint_id
}

output "bundle_id" {
  description = "Bundle / instance plan ID"
  value       = aws_lightsail_instance.wordpress.bundle_id
}

output "static_ip" {
  description = "Allocated Static Public IP address for the WordPress instance"
  value       = aws_lightsail_static_ip.wordpress.ip_address
}

output "cloudfront_distribution_id" {
  description = "CloudFront Distribution ID"
  value       = aws_cloudfront_distribution.wordpress.id
}

output "cloudfront_distribution_arn" {
  description = "CloudFront Distribution ARN"
  value       = aws_cloudfront_distribution.wordpress.arn
}

output "cloudfront_domain_name" {
  description = "CloudFront default domain name (point GoDaddy CNAME 'wp' to this value)"
  value       = aws_cloudfront_distribution.wordpress.domain_name
}
