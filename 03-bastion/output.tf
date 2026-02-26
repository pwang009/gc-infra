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

output "nlb_dns_name" {
  description = "DNS name of the VPN NLB"
  value       = aws_lb.vpn_nlb.dns_name
}

output "nlb_arn" {
  description = "ARN of the VPN NLB"
  value       = aws_lb.vpn_nlb.arn
}

output "nlb_zone_id" {
  description = "Zone ID of the VPN NLB for Route 53 alias"
  value       = aws_lb.vpn_nlb.zone_id
}

output "vpn_udp_target_group_arn" {
  description = "ARN of the VPN UDP target group"
  value       = aws_lb_target_group.vpn_udp.arn
}

output "vpn_admin_target_group_arn" {
  description = "ARN of the VPN Admin target group"
  value       = aws_lb_target_group.vpn_admin.arn
}

output "vpn_client_target_group_arn" {
  description = "ARN of the VPN Client target group"
  value       = aws_lb_target_group.vpn_client.arn
}
