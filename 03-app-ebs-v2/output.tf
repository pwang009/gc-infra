output "beanstalk_env_name" {
  value = aws_elastic_beanstalk_environment.gc_api_prod.name
}

output "beanstalk_asg_name" {
  value = aws_elastic_beanstalk_environment.gc_api_prod.resources[0].autoscaling_groups[0]
}
