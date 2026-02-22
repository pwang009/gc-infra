# Lookup the ASG name created by Elastic Beanstalk
data "aws_autoscaling_groups" "beanstalk_asg" {
  names = ["${aws_elastic_beanstalk_environment.gc_api_prod.name}"]
}

output "beanstalk_asg_names" {
  value = data.aws_autoscaling_groups.beanstalk_asg.names
}
output "beanstalk_env_name" {
  value = aws_elastic_beanstalk_environment.gc_api_prod.name
}


# The ASG name is not directly exported by aws_elastic_beanstalk_environment.
# If needed, use a data source to look up the ASG by environment name.
