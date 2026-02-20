resource "aws_elastic_beanstalk_application" "gc_api" {
  name        = "gc-api"
  description = "gc-api Java 21 app"
}
