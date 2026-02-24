resource "aws_security_group" "bastion_sg" {
  name        = "${var.environment}-bastion-sg"
  description = "Security group for bastion EC2 instance"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
    description = "SSH from VPC"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.network.outputs.vpc_cidr]
    description = "Application port from VPC"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.environment}-bastion-sg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
