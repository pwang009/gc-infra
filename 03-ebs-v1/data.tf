data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    key    = "${var.environment}/01-network/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "cognito" {
  backend = "s3"
  config = {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    key    = "${var.environment}/08-cognito/terraform.tfstate"
    region = var.aws_region
  }
}
