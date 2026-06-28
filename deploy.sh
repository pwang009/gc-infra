#!/bin/bash
set -e

# Load environment variables from .env file if it exists
if [ -f .env ]; then
  set -a
  source .env
  set +a
  echo "Loaded environment variables from .env"
else
  echo "Warning: .env file not found. Make sure TF_VAR_db_username and TF_VAR_db_password are set."
fi

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
# MODULES=(01-network 08-cognito)
# Note: 04-alb must come after 03-ebs-v1 since it needs the EBS state
MODULES=(01-network 02-db 03-bastion 03-ebs-v1 04-alb 05-ssm-access 08-cognito)
for DIR in "${MODULES[@]}"; do
  # Only init if --init flag is set OR if .terraform doesn't exist
  if [ "$INIT_FLAG" = "--init" ] || [ ! -d "$DIR/.terraform" ]; then
    echo "Initializing $DIR..."
    terraform -chdir=$DIR init -reconfigure -backend-config=../backend.config \
      -backend-config="key=$ENV/$DIR/terraform.tfstate"
  fi
  # Use module-specific tfvars file (e.g., tfvars/dev/01-network-dev.tfvars)
  TFVARS_FILENAME="${DIR}-${ENV}.tfvars"
  TFVARS_PATH="tfvars/${ENV}/${TFVARS_FILENAME}"
  if [ -f "$TFVARS_PATH" ]; then
    terraform -chdir=$DIR plan -var-file="../$TFVARS_PATH" -compact-warnings
    terraform -chdir=$DIR apply -var-file="../$TFVARS_PATH" -auto-approve -compact-warnings
  else
    echo "Error: $TFVARS_PATH not found"
    exit 1
  fi
done

echo "$ENV environment deployed successfully!"
