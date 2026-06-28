# Reference Beanstalk v1 (03-ebs-v1) for ASG name
data "terraform_remote_state" "app_ebs_v1" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "${var.environment}/03-ebs-v1/terraform.tfstate"
    region = var.aws_region
  }
}
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "${var.environment}/01-network/terraform.tfstate"
    region = var.aws_region
  }
}
