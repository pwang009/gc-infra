# Reference Beanstalk v1 (03-ebs-v1) for ASG name
data "terraform_remote_state" "app_ebs_v1" {
  backend = "s3"
  config = {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    key    = "${var.environment}/app-ebs-v1/terraform.tfstate"
    region = "us-west-1"
  }
}
data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    key    = "${var.environment}/network/terraform.tfstate"
    region = "us-west-1"
  }
}


data "terraform_remote_state" "app" {
  backend = "s3"
  config = {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    key    = "${var.environment}/app-ec2/terraform.tfstate"
    region = "us-west-1"
  }
}

# Reference Beanstalk v2 (03-app-ebs-v2) for ASG name
data "terraform_remote_state" "app_ebs_v2" {
  backend = "s3"
  config = {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    key    = "${var.environment}/app-ebs-v2/terraform.tfstate"
    region = "us-west-1"
  }
}
