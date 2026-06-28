data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "${var.environment}/01-network/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "cognito" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "${var.environment}/08-cognito/terraform.tfstate"
    region = var.aws_region
  }
}
