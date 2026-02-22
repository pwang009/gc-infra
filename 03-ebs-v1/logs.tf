resource "aws_elastic_beanstalk_configuration_template" "gc_api_logs" {
  name                = "gc-api-logs-template"
  application         = aws_elastic_beanstalk_application.gc_api.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.8.4 running Corretto 21"

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

}
