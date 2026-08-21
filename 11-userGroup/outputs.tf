output "api_testers_group_name" {
  description = "Name of the IAM group"
  value       = aws_iam_group.api_testers.name
}

output "api_testers_group_arn" {
  description = "ARN of the IAM group"
  value       = aws_iam_group.api_testers.arn
}

output "api_testers_policy_arn" {
  description = "ARN of the CloudWatch logs policy attached to the group"
  value       = aws_iam_policy.api_testers_cloudwatch_logs.arn
}
