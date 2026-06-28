output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.bastion.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.bastion.public_ip
}

output "instance_private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.bastion.private_ip
}

output "security_group_id" {
  description = "ID of the bastion security group"
  value       = aws_security_group.bastion_sg.id
}

output "iam_role_name" {
  description = "Name of the IAM role attached to the instance"
  value       = aws_iam_role.bastion_role.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to the instance"
  value       = aws_iam_role.bastion_role.arn
}

output "ssm_connect_command" {
  description = "AWS CLI command to connect to the instance via SSM"
  value       = "aws ssm start-session --target ${aws_instance.bastion.id}"
}
