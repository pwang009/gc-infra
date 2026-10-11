resource "aws_elastic_beanstalk_application" "gc_api" {
  name        = "gc-api-${var.environment}"
  description = "gc-api-${var.environment} Python 3.12 app"
}
