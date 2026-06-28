resource "aws_elastic_beanstalk_application" "gc_api" {
  name        = "gc-api"
  description = "gc-api Python 3.12 app"
}
