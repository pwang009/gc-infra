data "terraform_remote_state" "network" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "${var.environment}/01-network/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "db" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "${var.environment}/02-db/terraform.tfstate"
    region = var.aws_region
  }
}

data "terraform_remote_state" "ebs" {
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "${var.environment}/03-ebs-v1/terraform.tfstate"
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

data "terraform_remote_state" "s3_media" {
  count   = var.use_s3_media_remote_state ? 1 : 0
  backend = "s3"
  config = {
    bucket = var.terraform_state_bucket
    key    = "${var.environment}/10-s3/terraform.tfstate"
    region = var.aws_region
  }
}
