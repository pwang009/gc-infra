resource "aws_cloudwatch_log_group" "aurora_error" {
  name              = "/aws/rds/cluster/${aws_rds_cluster.aurora.cluster_identifier}/error"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "aurora_general" {
  name              = "/aws/rds/cluster/${aws_rds_cluster.aurora.cluster_identifier}/general"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "aurora_slowquery" {
  name              = "/aws/rds/cluster/${aws_rds_cluster.aurora.cluster_identifier}/slowquery"
  retention_in_days = 14
}
locals {
  serverless_mode = var.aurora_mode == "serverless"
}

resource "aws_rds_cluster" "aurora" {
  cluster_identifier              = "${var.environment}-aurora-cluster"
  engine                          = "aurora-mysql"
  engine_mode                     = "provisioned"
  engine_version                  = "8.0.mysql_aurora.3.04.4"
  database_name                   = var.db_name
  master_username                 = var.db_username
  master_password                 = var.db_password
  db_subnet_group_name            = aws_db_subnet_group.aurora.name
  vpc_security_group_ids          = [aws_security_group.rds_sg.id]
  backup_retention_period         = var.backup_retention_period
  preferred_backup_window         = var.preferred_backup_window
  preferred_maintenance_window    = var.preferred_maintenance_window
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  skip_final_snapshot             = var.environment == "dev" ? true : false
  final_snapshot_identifier       = var.environment == "dev" ? null : "${var.environment}-aurora-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  deletion_protection             = false

  dynamic "serverlessv2_scaling_configuration" {
    for_each = local.serverless_mode ? [1] : []
    content {
      min_capacity = var.serverless_min_capacity
      max_capacity = var.serverless_max_capacity
    }
  }

  tags = {
    Name        = "${var.environment}-aurora-cluster"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  lifecycle {
    ignore_changes = [final_snapshot_identifier]
  }
}

resource "aws_rds_cluster_instance" "aurora_instances" {
  count              = var.instance_count
  identifier         = "${var.environment}-aurora-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.aurora.id
  instance_class     = local.serverless_mode ? "db.serverless" : var.instance_class
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  tags = {
    Name        = "${var.environment}-aurora-instance-${count.index + 1}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_db_subnet_group" "aurora" {
  name       = "${var.environment}-aurora-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.database_subnets

  tags = {
    Name        = "${var.environment}-aurora-subnet-group"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
