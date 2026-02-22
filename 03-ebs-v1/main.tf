
# Elastic Beanstalk for gc-api (prod only)

provider "aws" {
  region = var.aws_region
}

# Example usage of remote state outputs:
# vpc_id = data.terraform_remote_state.network.outputs.vpc_id
# vpc_cidr = data.terraform_remote_state.network.outputs.vpc_cidr
# private_subnets = data.terraform_remote_state.network.outputs.private_subnets
# public_subnets = data.terraform_remote_state.network.outputs.public_subnets
