resource "aws_lb" "vpn_nlb" {
  name               = "${var.environment}-vpn-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = data.terraform_remote_state.network.outputs.public_subnets

  enable_deletion_protection = var.environment == "prod" ? true : false

  tags = {
    Name        = "${var.environment}-vpn-nlb"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Target group for OpenVPN (UDP 1194)
resource "aws_lb_target_group" "vpn_udp" {
  name        = "${var.environment}-vpn-udp-tg"
  port        = 1194
  protocol    = "UDP"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    port                = "943"
    protocol            = "TCP"
  }

  tags = {
    Name        = "${var.environment}-vpn-udp-tg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Target group for OpenVPN Admin (TCP 943)
resource "aws_lb_target_group" "vpn_admin" {
  name        = "${var.environment}-vpn-admin-tg"
  port        = 943
  protocol    = "TCP"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    port                = "943"
    protocol            = "TCP"
  }

  tags = {
    Name        = "${var.environment}-vpn-admin-tg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Target group for OpenVPN Client Profile Download (TCP 443)
resource "aws_lb_target_group" "vpn_client" {
  name        = "${var.environment}-vpn-client-tg"
  port        = 443
  protocol    = "TCP"
  vpc_id      = data.terraform_remote_state.network.outputs.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    unhealthy_threshold = 2
    interval            = 30
    port                = "443"
    protocol            = "TCP"
  }

  tags = {
    Name        = "${var.environment}-vpn-client-tg"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

# Listener for UDP 1194 (OpenVPN tunnel)
resource "aws_lb_listener" "vpn_udp" {
  load_balancer_arn = aws_lb.vpn_nlb.arn
  port              = "1194"
  protocol          = "UDP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpn_udp.arn
  }
}

# Listener for TCP 943 (OpenVPN Admin) - TCP Passthrough
resource "aws_lb_listener" "vpn_admin" {
  load_balancer_arn = aws_lb.vpn_nlb.arn
  port              = "943"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpn_admin.arn
  }
}

# Listener for TCP 443 (OpenVPN Client Profile) - TCP Passthrough
resource "aws_lb_listener" "vpn_client" {
  load_balancer_arn = aws_lb.vpn_nlb.arn
  port              = "443"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.vpn_client.arn
  }
}

# Attach bastion instance to VPN UDP target group
resource "aws_lb_target_group_attachment" "vpn_udp" {
  target_group_arn = aws_lb_target_group.vpn_udp.arn
  target_id        = aws_instance.bastion.id
  port             = 1194
}

# Attach bastion instance to VPN Admin target group
resource "aws_lb_target_group_attachment" "vpn_admin" {
  target_group_arn = aws_lb_target_group.vpn_admin.arn
  target_id        = aws_instance.bastion.id
  port             = 943
}

# Attach bastion instance to VPN Client target group
resource "aws_lb_target_group_attachment" "vpn_client" {
  target_group_arn = aws_lb_target_group.vpn_client.arn
  target_id        = aws_instance.bastion.id
  port             = 443
}
