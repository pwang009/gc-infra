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
# Note: 08-cognito should come before 03-ebs-v1 because the Beanstalk role policy
# references the Cognito user pool ARN from the Cognito stack.
MODULES=(01-network 02-db 03-bastion 08-cognito 03-ebs-v1 04-alb 05-ssm-access 07-cicd)
for DIR in "${MODULES[@]}"; do
  # Only init if --init flag is set OR if .terraform doesn't exist
  if [ "$INIT_FLAG" = "--init" ] || [ ! -d "$DIR/.terraform" ]; then
    echo "Initializing $DIR..."
    terraform -chdir=$DIR init -reconfigure -backend-config=../backend.config \
      -backend-config="key=$ENV/$DIR/terraform.tfstate"
  fi

  TFVARS_FILENAME="${DIR}-${ENV}.tfvars"
  TFVARS_PATH="tfvars/${ENV}/${TFVARS_FILENAME}"
  if [ -f "$TFVARS_PATH" ]; then
    echo "Using tfvars file: $TFVARS_PATH"
    terraform -chdir=$DIR plan -var-file="../$TFVARS_PATH" -compact-warnings
    terraform -chdir=$DIR apply -var-file="../$TFVARS_PATH" -auto-approve -compact-warnings
  else
    echo "Warning: $TFVARS_PATH not found; skipping plan/apply for $DIR"
  fi
done

echo "$ENV environment deployed successfully!"
