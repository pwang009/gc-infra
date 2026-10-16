resource "aws_elastic_beanstalk_application" "gc_api" {
  name        = var.environment == "prod" ? "gc-api" : "gc-api-${var.environment}"
  description = "${var.environment == "prod" ? "gc-api" : "gc-api-${var.environment}"} Python 3.12 app"
}

