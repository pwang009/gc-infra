output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.app.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.app.arn
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.app.zone_id
}


output "target_group_arn" {
  description = "ARN of the v1 target group"
  value       = aws_lb_target_group.app_v1.arn
}

# output "target_group_v2_arn" - commented out, app_v2 target group not in use
# output "target_group_v2_arn" {
#   description = "ARN of the v2 target group"
#   value       = aws_lb_target_group.app_v2.arn
# }


output "alb_url_v1" {
  description = "URL to access the v1 application"
  value       = "https://${aws_lb.app.dns_name}/v1"
}

# output "alb_url_v2" - commented out, app_v2 target group not in use
# output "alb_url_v2" {
#   description = "URL to access the v2 application"
#   value       = "https://${aws_lb.app.dns_name}/v2"
# }
