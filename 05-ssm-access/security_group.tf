# Security group for SSM EC2 instance
resource "aws_security_group" "ssm_ec2_sg" {
  name        = "${var.environment}-ssm-ec2-sg"
  description = "Security group for SSM EC2 bastion instance"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  # Allow outbound to RDS
  egress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.db.outputs.security_group_id]
  }

  # Allow all outbound for SSM and updates
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-ssm-ec2-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}