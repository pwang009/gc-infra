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
