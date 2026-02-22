# Lookup the ASG name created by Elastic Beanstalk
data "aws_autoscaling_groups" "beanstalk_asg" {
  names = ["${aws_elastic_beanstalk_environment.gc_api_prod.name}"]
}
# Lookup the load balancer created by Elastic Beanstalk
data "aws_lb" "beanstalk_lb" {
  arn = aws_elastic_beanstalk_environment.gc_api_prod.load_balancers[0]
}
output "beanstalk_asg_names" {
  value = data.aws_autoscaling_groups.beanstalk_asg.names
}
output "beanstalk_env_name" {
  value = aws_elastic_beanstalk_environment.gc_api_prod.name
}
output "beanstalk_lb_name" {
  value = data.aws_lb.beanstalk_lb.name
}
output "beanstalk_lb_arn" {
  value = data.aws_lb.beanstalk_lb.arn
}
output "beanstalk_lb_dns_name" {
  value = data.aws_lb.beanstalk_lb.dns_name
}


# The ASG name is not directly exported by aws_elastic_beanstalk_environment.
# If needed, use a data source to look up the ASG by environment name.
