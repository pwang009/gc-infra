resource "aws_elastic_beanstalk_environment" "gc_api_prod" {
  name                = "gc-api-prod"
  application         = aws_elastic_beanstalk_application.gc_api.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.0.0 running Corretto 21"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = var.instance_type
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
    namespace = "aws:autoscaling:asg"
    name      = "DesiredCapacity"
    value     = var.desired_capacity
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = module.network.vpc_id
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", module.network.private_subnets)
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = join(",", module.network.public_subnets)
  }
  setting {
    namespace = "aws:ec2:vpc"
    name      = "SecurityGroups"
    value     = aws_security_group.beanstalk.id
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "LoadBalancerType"
    value     = "application"
  }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
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
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:logfiles"
    name      = "/var/log/web.stdout.log"
    value     = "true"
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:logfiles"
    name      = "/var/log/web.stderr.log"
    value     = "true"
  }
  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs:logfiles"
    name      = "/var/log/eb-engine.log"
    value     = "true"
  }
  tags = {
    Name = "gc-api-prod"
    Environment = "prod"
  }
}
