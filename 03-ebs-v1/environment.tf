resource "aws_elastic_beanstalk_environment" "gc_api_prod" {
  name                = "gc-api-prod"
  application         = aws_elastic_beanstalk_application.gc_api.name
  platform_arn = "arn:aws:elasticbeanstalk:us-west-1::platform/Corretto 21 running on 64bit Amazon Linux 2023/4.9.0"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_ec2_profile.name
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MinSize"
    value     = var.min_size
  }
  setting {
    namespace = "aws:autoscaling:asg"
    name      = "MaxSize"
    value     = var.max_size
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = data.terraform_remote_state.network.outputs.vpc_id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", data.terraform_remote_state.network.outputs.private_subnets)
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", data.terraform_remote_state.network.outputs.public_subnets)
  }
  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.beanstalk.id
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }
  # Enable HTTP to HTTPS redirect
  setting {
    namespace = "aws:elbv2:listener:80"
    name      = "ListenerEnabled"
    value     = "true"
  }
  setting {
    namespace = "aws:elbv2:listener:80"
    name      = "Protocol"
    value     = "HTTP"
  }
  # aws acm request-certificate --domain-name api.lishanteala.com --validation-method DNS --region us-west-1
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "ListenerEnabled"
    value     = "true"
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "Protocol"
    value     = "HTTPS"
  }
  setting {
    namespace = "aws:elbv2:listener:443"
    name      = "SSLCertificateArns"
    value     = var.ssl_certificate_arn
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name      = "HealthCheckPath"
    value     = "/actuator/health"
  }
    # Set PORT environment variable for Spring Boot
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "PORT"
    value     = var.app_port
  }

  # CloudWatch log streaming
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "DeleteOnTerminate"
    value     = "false"
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "RetentionInDays"
    value     = "14"
  }
  tags = {
    Name = "gc-api-prod"
    Environment = "prod"
  }
}

# Enable ALB access logs via CLI since EB settings don't support it
resource "null_resource" "enable_alb_access_logs" {
  depends_on = [aws_elastic_beanstalk_environment.gc_api_prod, aws_s3_bucket.alb_access_logs]

  provisioner "local-exec" {
    command = "aws elbv2 modify-load-balancer-attributes --load-balancer-arn ${aws_elastic_beanstalk_environment.gc_api_prod.load_balancers[0]} --attributes Key=access_logs.s3.enabled,Value=true Key=access_logs.s3.bucket,Value=${aws_s3_bucket.alb_access_logs.bucket}"
  }
}

# Data source to get the HTTP listener created by Elastic Beanstalk
data "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_elastic_beanstalk_environment.gc_api_prod.load_balancers[0]
  port              = 80
}

# Listener rule to redirect HTTP to HTTPS
resource "aws_lb_listener_rule" "redirect_http_to_https" {
  listener_arn = data.aws_lb_listener.http_listener.arn
  priority     = 1

  action {
    type = "redirect"
    redirect {
      protocol    = "HTTPS"
      port        = "443"
      status_code = "HTTP_301"
    }
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}
