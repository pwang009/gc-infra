output "user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.main.id
}

output "user_pool_arn" {
  description = "Cognito User Pool ARN"
  value       = aws_cognito_user_pool.main.arn
}

output "app_client_id" {
  description = "Cognito App Client ID"
  value       = aws_cognito_user_pool_client.app.id
}

output "lambda_define_challenge_arn" {
  description = "Define Challenge Lambda ARN"
  value       = aws_lambda_alias.cognito_triggers["defineChallenge"].arn
}

output "lambda_generate_otp_arn" {
  description = "Generate OTP Lambda ARN"
  value       = aws_lambda_alias.cognito_triggers["generateOTP"].arn
}

output "lambda_validate_challenge_arn" {
  description = "Validate Challenge Lambda ARN"
  value       = aws_lambda_alias.cognito_triggers["validateChallenge"].arn
}

output "cloudtrail_log_group_name" {
  description = "CloudWatch log group name for CloudTrail Cognito events"
  value       = aws_cloudwatch_log_group.cloudtrail.name
}

output "cloudtrail_log_group_arn" {
  description = "CloudWatch log group ARN for CloudTrail Cognito events"
  value       = aws_cloudwatch_log_group.cloudtrail.arn
}

output "lambda_log_group_name" {
  description = "CloudWatch log group name for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda_logs.name
}

output "lambda_log_group_arn" {
  description = "CloudWatch log group ARN for Lambda logs"
  value       = aws_cloudwatch_log_group.lambda_logs.arn
}
