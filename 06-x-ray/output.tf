output "sampling_rule_arn" {
  description = "ARN of the X-Ray sampling rule"
  value       = aws_xray_sampling_rule.gc_api_sampling.arn
}

output "sampling_rule_name" {
  description = "Name of the X-Ray sampling rule"
  value       = aws_xray_sampling_rule.gc_api_sampling.rule_name
}

output "group_arn" {
  description = "ARN of the X-Ray group"
  value       = aws_xray_group.gc_api_group.arn
}

output "group_name" {
  description = "Name of the X-Ray group"
  value       = aws_xray_group.gc_api_group.group_name
}

output "log_group_name" {
  description = "CloudWatch log group name for X-Ray insights"
  value       = aws_cloudwatch_log_group.xray_insights.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN for X-Ray insights"
  value       = aws_cloudwatch_log_group.xray_insights.arn
}
