data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    key    = "${var.environment}/01-network/terraform.tfstate"
    region = "us-west-1"
  }
}

data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }
}
