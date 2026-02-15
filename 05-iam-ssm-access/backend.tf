terraform {
  backend "s3" {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    key    = "iam-ssm-access/terraform.tfstate"
    region = "us-west-1"
  }
}
