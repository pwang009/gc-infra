resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.ec2_instance_type

  iam_instance_profile = aws_iam_instance_profile.bastion_profile.name

  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  subnet_id = data.terraform_remote_state.network.outputs.private_subnets[0]

  user_data_base64 = base64encode(file("${path.module}/user_data.sh"))

  tags = {
    Name        = "gc-bastion-${var.environment}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
    tags = {
      Name        = "gc-bastion-${var.environment}-volume"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
