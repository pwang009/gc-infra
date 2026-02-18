terraform {
  backend "s3" {
    bucket = "gc-terraform-state-c8f7ewhysy5a"
    # key is set via -backend-config in deploy.sh
    # dev: key = "dev/db/terraform.tfstate"
    # prod: key = "prod/db/terraform.tfstate"
    region = "us-west-1"
  }
}
