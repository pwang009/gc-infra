terraform {
  backend "s3" {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    # key is set via -backend-config in deploy.sh
    # dev: key = "dev/network/terraform.tfstate"
    # prod: key = "prod/network/terraform.tfstate"
    region = "us-west-1"
  }
}
