data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    key    = "${var.environment}/network/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "app_ebs_v1" {
  backend = "s3"
  config = {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    key    = "${var.environment}/app-ebs-v1/terraform.tfstate"
    region = var.aws_region
  }
}
