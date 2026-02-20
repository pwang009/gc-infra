resource "aws_elastic_beanstalk_configuration_template" "gc_api_logs" {
  name                = "gc-api-logs-template"
  application         = aws_elastic_beanstalk_application.gc_api.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.0.0 running Corretto 21"

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
}
