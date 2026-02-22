resource "aws_lb" "app" {
  name               = "${var.environment}-app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.terraform_remote_state.network.outputs.public_subnets

  enable_deletion_protection = var.environment == "prod" ? true : false

  access_logs {
    bucket  = aws_s3_bucket.alb_access_logs.bucket
    prefix  = "${var.environment}/AWSLogs/${data.aws_caller_identity.current.account_id}/"
    enabled = true
  }

  tags = {
    Name        = "${var.environment}-app-alb"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_target_group" "app_v1" {
  name     = "${var.environment}-app-v1-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = var.health_check_path
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.environment}-app-v1-tg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Target group for Beanstalk v2 (gc-api)
resource "aws_lb_target_group" "app_v2" {
  name     = "${var.environment}-app-v2-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.network.outputs.vpc_id

  health_check {
    enabled             = true
    healthy_threshold   = var.healthy_threshold
    unhealthy_threshold = var.unhealthy_threshold
    timeout             = var.health_check_timeout
    interval            = var.health_check_interval
    path                = "/"
    matcher             = "200"
  }

  deregistration_delay = 30

  tags = {
    Name        = "${var.environment}-app-v2-tg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_v1.arn
  }
}

resource "aws_lb_listener_rule" "v1_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_v1.arn
  }

  condition {
    path_pattern {
      values = ["/v1/*"]
    }
  }
}

# Listener rule for v2 path
resource "aws_lb_listener_rule" "v2_path" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 110

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_v2.arn
  }

  condition {
    path_pattern {
      values = ["/v2/*"]
    }
  }
}

# Attach Beanstalk ASG to v1 target group
resource "aws_autoscaling_attachment" "app_v1" {
  autoscaling_group_name = data.terraform_remote_state.app_ebs_v1.outputs.beanstalk_asg_name
  lb_target_group_arn    = aws_lb_target_group.app_v1.arn
}

# Attach Beanstalk ASG to v2 target group
resource "aws_autoscaling_attachment" "app_v2" {
  autoscaling_group_name = data.terraform_remote_state.app_ebs_v2.outputs.beanstalk_asg_name
  lb_target_group_arn    = aws_lb_target_group.app_v2.arn
}
