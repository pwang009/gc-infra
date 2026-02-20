resource "aws_security_group" "beanstalk" {
  name        = "gc-api-beanstalk-prod"
  description = "Allow traffic for Beanstalk app instances"
  vpc_id      = module.network.vpc_id

    ingress {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      security_groups = [data.terraform_remote_state.load_balancer.outputs.alb_sg_id]
      description = "Allow ALB to reach Beanstalk instances"
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
      Name = "gc-api-beanstalk-prod"
      Environment = "prod"
    }
  }

  # Data source to get ALB SG ID from 04-load-balancer
  data "terraform_remote_state" "load_balancer" {
    backend = "s3"
    config = {
      bucket = "gc-terraform-state-c8f7ewhysy5a"
      key    = "prod/load-balancer/terraform.tfstate"
      region = "us-west-1"
    }
  }
}
