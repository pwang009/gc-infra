#!/bin/bash
set -e

ENV=$1

if [ -z "$ENV" ]; then
  echo "Usage: ./destroy.sh <dev|prod>"
  exit 1
fi

if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
  echo "Error: Environment must be 'dev' or 'prod'"
  exit 1
fi

echo "Destroying $ENV environment..."

terraform -chdir=05-iam-ssm-access destroy -var-file=$ENV.tfvars -auto-approve

terraform -chdir=04-load-balancer destroy -var-file=$ENV.tfvars -auto-approve

terraform -chdir=03-app-ec2-v1 destroy -var-file=$ENV.tfvars -auto-approve

terraform -chdir=02-db destroy -var-file=$ENV.tfvars -auto-approve

terraform -chdir=01-network destroy -var-file=$ENV.tfvars -auto-approve

echo "$ENV environment destroyed successfully!"
