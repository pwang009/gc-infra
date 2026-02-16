resource "aws_db_proxy" "aurora_proxy" {
  count                  = var.enable_proxy ? 1 : 0
  name                   = "${var.environment}-aurora-proxy"
  engine_family          = "POSTGRESQL"
  auth {
    auth_scheme = "SECRETS"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db_credentials[0].arn
  }

  role_arn               = aws_iam_role.rds_proxy[0].arn
  vpc_subnet_ids         = data.terraform_remote_state.network.outputs.database_subnets
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  require_tls = true

  tags = {
    Name        = "${var.environment}-aurora-proxy"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_db_proxy_default_target_group" "aurora_proxy" {
  count         = var.enable_proxy ? 1 : 0
  db_proxy_name = aws_db_proxy.aurora_proxy[0].name

  connection_pool_config {
    max_connections_percent      = 100
    max_idle_connections_percent = 50
  }
}

resource "aws_db_proxy_target" "aurora_proxy" {
  count                 = var.enable_proxy ? 1 : 0
  db_proxy_name         = aws_db_proxy.aurora_proxy[0].name
  target_group_name     = aws_db_proxy_default_target_group.aurora_proxy[0].name
  db_cluster_identifier = aws_rds_cluster.aurora.cluster_identifier
}

resource "aws_secretsmanager_secret" "db_credentials" {
  count = var.enable_proxy ? 1 : 0
  name  = "${var.environment}-aurora-credentials-${random_id.secret_suffix[0].hex}"

  tags = {
    Name        = "${var.environment}-aurora-credentials"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  count     = var.enable_proxy ? 1 : 0
  secret_id = aws_secretsmanager_secret.db_credentials[0].id
  secret_string = jsonencode({
    username = var.db_username
    password = var.db_password
  })
}

resource "random_id" "secret_suffix" {
  count       = var.enable_proxy ? 1 : 0
  byte_length = 4
}

resource "aws_iam_role" "rds_proxy" {
  count = var.enable_proxy ? 1 : 0
  name  = "${var.environment}-rds-proxy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "rds.amazonaws.com"
      }
    }]
  })

  tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy" "rds_proxy" {
  count = var.enable_proxy ? 1 : 0
  name  = "${var.environment}-rds-proxy-policy"
  role  = aws_iam_role.rds_proxy[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "secretsmanager:GetSecretValue"
      ]
      Resource = aws_secretsmanager_secret.db_credentials[0].arn
    }]
  })
}
