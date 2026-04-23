resource "aws_cloudwatch_log_group" "beanstalk_eb_engine_logs" {
  name              = "/aws/elasticbeanstalk/gc-api-prod/var/log/eb-engine.log"
  retention_in_days = 14

  tags = {
    Name        = "gc-api-prod-eb-engine-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "beanstalk_web_stdout_logs" {
  name              = "/aws/elasticbeanstalk/gc-api-prod/var/log/web.stdout.log"
  retention_in_days = 14

  tags = {
    Name        = "gc-api-prod-web-stdout-logs"
    Environment = var.environment
  }
}

