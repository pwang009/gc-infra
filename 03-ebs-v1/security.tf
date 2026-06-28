resource "aws_security_group" "beanstalk" {
  name        = "gc-api-beanstalk-${var.environment}"
  description = "Allow traffic for Beanstalk app instances"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id

    ingress {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"] # Replace with a more restrictive rule if needed
      description = "Allow traffic to Beanstalk instances"
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "gc-api-beanstalk-${var.environment}"
      Environment = var.environment
    }
  }
