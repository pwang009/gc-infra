output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

output "launch_template_id" {
  description = "ID of the Launch Template"
  value       = aws_launch_template.app.id
}

output "launch_template_latest_version" {
  description = "Latest version of the Launch Template"
  value       = aws_launch_template.app.latest_version
}

output "security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.app_sg.id
}

output "iam_role_name" {
  description = "Name of the IAM role attached to instances"
  value       = aws_iam_role.app_role.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to instances"
  value       = aws_iam_role.app_role.arn
}

output "instance_ids_command" {
  description = "AWS CLI command to list instance IDs in the ASG"
  value       = "aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names ${aws_autoscaling_group.app.name} --query 'AutoScalingGroups[0].Instances[*].InstanceId' --output table"
}

output "ssm_connect_command" {
  description = "AWS CLI command to connect to instances via SSM"
  value       = "aws ssm start-session --target <instance-id>"
}
