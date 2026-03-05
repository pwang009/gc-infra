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

# Initialize and apply infrastructure for each module
 echo "Initializing and applying Terraform..."
MODULES=(01-network 02-db 03-bastion 03-ebs-v1 04-alb 05-ssm-access)
for DIR in "${MODULES[@]}"; do
  [ "$INIT_FLAG" = "--init" ] && \
  terraform -chdir=$DIR init -reconfigure -backend-config=../backend.config \
    -backend-config="key=$ENV/$DIR/terraform.tfstate"
  terraform -chdir=$DIR plan -var-file=$ENV.tfvars
  terraform -chdir=$DIR apply -var-file=$ENV.tfvars -auto-approve
done

echo "$ENV environment deployed successfully!"
