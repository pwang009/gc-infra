
# Elastic Beanstalk for gc-api (prod only)

module "network" {
  source = "../01-network"
}

provider "aws" {
  region = var.aws_region
}
