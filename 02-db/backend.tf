terraform {
  backend "s3" {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    key    = "db/terraform.tfstate"
    region = "us-west-1"
  }
}
