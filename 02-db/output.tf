output "cluster_endpoint" {
  description = "Aurora cluster endpoint (writer)"
  value       = aws_rds_cluster.aurora.endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = aws_rds_cluster.aurora.reader_endpoint
}

output "cluster_id" {
  description = "Aurora cluster identifier"
  value       = aws_rds_cluster.aurora.cluster_identifier
}

output "database_name" {
  description = "Database name"
  value       = aws_rds_cluster.aurora.database_name
}

output "proxy_endpoint" {
  description = "RDS Proxy endpoint (if enabled)"
  value       = var.enable_proxy ? aws_db_proxy.aurora_proxy[0].endpoint : null
}

output "connection_endpoint" {
  description = "Recommended connection endpoint (proxy if enabled, otherwise cluster)"
  value       = var.enable_proxy ? aws_db_proxy.aurora_proxy[0].endpoint : aws_rds_cluster.aurora.endpoint
}

output "security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds_sg.id
}
