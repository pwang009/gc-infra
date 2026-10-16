output "environment_name" {
  description = "Target Elastic Beanstalk environment name"
  value       = local.environment_name
}

output "application_name" {
  description = "Elastic Beanstalk application name"
  value       = local.app_name
}

output "configured_properties" {
  description = "List of configured environment property keys"
  value       = keys(local.env_properties)
}

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID populated from 08-cognito remote state"
  value       = local.cognito_user_pool_id
}

output "cognito_user_pool_arn" {
  description = "Cognito User Pool ARN populated from 08-cognito remote state"
  value       = local.cognito_user_pool_arn
}

output "cognito_app_client_id" {
  description = "Cognito App Client ID populated from 08-cognito remote state"
  value       = local.cognito_app_client_id
}

output "db_url" {
  description = "Database connection URL populated from 02-db remote state"
  value       = local.db_url
}

output "db_name" {
  description = "Database name populated from 02-db remote state"
  value       = local.db_name
}

output "redis_host" {
  description = "Redis host populated from 02-db remote state"
  value       = local.redis_host
}

output "redis_port" {
  description = "Redis port populated from 02-db remote state"
  value       = local.redis_port
}

output "media_s3_bucket" {
  description = "Media S3 bucket populated from 10-s3 remote state"
  value       = local.media_s3_bucket
}
