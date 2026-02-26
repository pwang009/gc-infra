terraform {
  backend "s3" {
    bucket         = "gc-terraform-state-c8f7ewhysy5a"
    key            = "prod/x-ray/terraform.tfstate"
    region         = "us-west-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
