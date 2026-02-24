# EC2 instance for SSM port forwarding
resource "aws_instance" "ec2_ssm_bastion" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro"
  subnet_id              = data.terraform_remote_state.network.outputs.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.ssm_ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm_ec2_profile.name
  user_data = <<-EOF
    #!/bin/bash
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF
  tags = {
    Name        = "${var.environment}-ssm-bastion"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}