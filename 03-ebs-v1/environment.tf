resource "aws_elastic_beanstalk_environment" "gc_api_prod" {
  name                = "gc-api-prod"
  application         = aws_elastic_beanstalk_application.gc_api.name
  platform_arn = "arn:aws:elasticbeanstalk:us-west-1::platform/Corretto 21 running on 64bit Amazon Linux 2023/4.8.4"

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
  # aws acm request-certificate --domain-name api.abc.com --validation-method DNS --region us-west-1
  # setting {
  #   namespace = "aws:elbv2:listener:443"
  #   name      = "ListenerEnabled"
  #   value     = "true"
  # }
  # setting {
  #   namespace = "aws:elbv2:listener:443"
  #   name      = "Protocol"
  #   value     = "HTTPS"
  # }
  # setting {
  #   namespace = "aws:elbv2:listener:443"
  #   name      = "SSLCertificateArns"
  #   value     = "arn:aws:acm:us-west-1:681742558891:certificate/ccee43f2-22ed-4f9f-b3ee-3281367786b9"
  # }
  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
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
