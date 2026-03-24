terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  backend "s3" {
    encrypt = true
  }
}

provider "aws" {
  region = "us-west-1"

  default_tags {
    tags = {
      Project = "gc-api"
    }
  }
}
