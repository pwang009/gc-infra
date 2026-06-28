resource "aws_cloudwatch_log_group" "beanstalk_eb_engine_logs" {
  name              = "/aws/elasticbeanstalk/gc-api-${var.environment}/var/log/eb-engine.log"
  retention_in_days = 14

  tags = {
    Name        = "gc-api-${var.environment}-eb-engine-logs"
    Environment = var.environment
  }
}

resource "aws_cloudwatch_log_group" "beanstalk_web_stdout_logs" {
  name              = "/aws/elasticbeanstalk/gc-api-${var.environment}/var/log/web.stdout.log"
  retention_in_days = 14

  tags = {
    Name        = "gc-api-${var.environment}-web-stdout-logs"
    Environment = var.environment
  }
}

