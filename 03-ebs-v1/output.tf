# Lookup the ASG name created by Elastic Beanstalk (name is auto-generated, filter by tag)
data "aws_autoscaling_groups" "beanstalk_asg" {
  filter {
    name   = "tag:elasticbeanstalk:environment-name"
    values = [aws_elastic_beanstalk_environment.gc_api.name]
  }
}
output "beanstalk_asg_names" {
  value = data.aws_autoscaling_groups.beanstalk_asg.names
}
output "beanstalk_env_name" {
  value = aws_elastic_beanstalk_environment.gc_api.name
}


# The ASG name is not directly exported by aws_elastic_beanstalk_environment.
# If needed, use a data source to look up the ASG by environment name.
