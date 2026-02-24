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

output "ec2_ssm_bastion_instance_id" {
  description = "Instance ID of the SSM bastion EC2"
  value       = aws_instance.ec2_ssm_bastion.id
}

output "ec2_ssm_bastion_private_ip" {
  description = "Private IP of the SSM bastion EC2"
  value       = aws_instance.ec2_ssm_bastion.private_ip
}
