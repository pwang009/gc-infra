#!/bin/bash
set -e

ENV=$1
INIT_FLAG=$2
LOCK_FILE="/tmp/terraform-deploy-${ENV}.lock"

if [ -z "$ENV" ]; then
  echo "Usage: ./deploy.sh <dev|prod> [--init]"
  exit 1
fi

if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
  echo "Error: Environment must be 'dev' or 'prod'"
  exit 1
fi

# Check for lock file
if [ -f "$LOCK_FILE" ]; then
  echo "Error: Another deployment for $ENV is already running."
  echo "If this is incorrect, remove: $LOCK_FILE"
  exit 1
fi

# Create lock file
echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

echo "Deploying $ENV environment..."

# Initialize if requested
if [ "$INIT_FLAG" = "--init" ]; then
  echo "Initializing Terraform..."
  terraform -chdir=01-network init -reconfigure -backend-config="key=$ENV/network/terraform.tfstate"
  terraform -chdir=02-db init -reconfigure -backend-config="key=$ENV/db/terraform.tfstate"
  terraform -chdir=03-app-ec2-v1 init -reconfigure -backend-config="key=$ENV/app-ec2/terraform.tfstate"
  terraform -chdir=04-load-balancer init -reconfigure -backend-config="key=$ENV/load-balancer/terraform.tfstate"
  terraform -chdir=05-iam-ssm-access init -reconfigure -backend-config="key=$ENV/iam-ssm-access/terraform.tfstate"
fi

# Apply infrastructure
terraform -chdir=01-network apply -var-file=$ENV.tfvars -auto-approve
terraform -chdir=02-db apply -var-file=$ENV.tfvars -auto-approve
terraform -chdir=03-app-ec2-v1 apply -var-file=$ENV.tfvars -auto-approve
terraform -chdir=04-load-balancer apply -var-file=$ENV.tfvars -auto-approve
terraform -chdir=05-iam-ssm-access apply -var-file=$ENV.tfvars -auto-approve

echo "$ENV environment deployed successfully!"
