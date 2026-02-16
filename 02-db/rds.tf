resource "aws_rds_cluster" "aurora" {
  cluster_identifier              = "${var.environment}-aurora-cluster"
  engine                          = "aurora-mysql"
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
  deletion_protection             = var.environment == "prod" ? true : false

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
  instance_class     = var.instance_class
  engine             = aws_rds_cluster.aurora.engine
  engine_version     = aws_rds_cluster.aurora.engine_version

  performance_insights_enabled = var.environment == "prod" ? true : false

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
