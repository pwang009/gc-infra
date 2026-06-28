resource "aws_elasticache_subnet_group" "redis" {
  count      = var.enable_redis ? 1 : 0
  name       = "${var.environment}-redis-subnet-group"
  subnet_ids = data.terraform_remote_state.network.outputs.database_subnets

  tags = {
    Name        = "${var.environment}-redis-subnet-group"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_security_group" "redis_sg" {
  count       = var.enable_redis ? 1 : 0
  name        = "${var.environment}-redis-sg"
  description = "Security group for ElastiCache Redis"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
    description = "Redis from within the VPC (Beanstalk app instances)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-redis-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_elasticache_replication_group" "redis" {
  count                = var.enable_redis ? 1 : 0
  replication_group_id = "${var.environment}-redis"
  description          = "${var.environment} token cache"
  engine               = var.redis_engine
  engine_version       = var.redis_engine_version
  node_type            = var.redis_node_type
  num_cache_clusters   = 1
  parameter_group_name = var.redis_parameter_group_name
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.redis[0].name
  security_group_ids   = [aws_security_group.redis_sg[0].id]

  tags = {
    Name        = "${var.environment}-redis"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
