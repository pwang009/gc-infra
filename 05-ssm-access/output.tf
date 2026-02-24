output "policy_arn" {
  description = "ARN of the SSM access policy"
  value       = aws_iam_policy.ssm_access.arn
}

output "policy_name" {
  description = "Name of the SSM access policy"
  value       = aws_iam_policy.ssm_access.name
}

output "iam_group_name" {
  description = "Name of the IAM group for SSM users"
  value       = aws_iam_group.ssm_users.name
}

output "iam_group_arn" {
  description = "ARN of the IAM group for SSM users"
  value       = aws_iam_group.ssm_users.arn
}

# EC2 instance outputs removed - instance no longer exists
