
# Elastic Beanstalk for gc-api (prod only)

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

# Example usage of remote state outputs:
# vpc_id = data.terraform_remote_state.network.outputs.vpc_id
# vpc_cidr = data.terraform_remote_state.network.outputs.vpc_cidr
# private_subnets = data.terraform_remote_state.network.outputs.private_subnets
# public_subnets = data.terraform_remote_state.network.outputs.public_subnets
