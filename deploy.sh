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
shift || true

LOCK_FILE="/tmp/terraform-deploy-${ENV}.lock"
INIT=false
TARGET_MODULE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --init)
      INIT=true
      shift
      ;;
    *)
      if [ -z "$TARGET_MODULE" ]; then
        TARGET_MODULE="${1%/}" # strip trailing slash if provided
        shift
      else
        echo "Error: Unexpected argument '$1'"
        echo "Usage: ./deploy.sh <dev|prod> [module_dir] [--init]"
        exit 1
      fi
      ;;
  esac
done

if [ -z "$ENV" ]; then
  echo "Usage: ./deploy.sh <dev|prod> [module_dir] [--init]"
  echo "Examples:"
  echo "  ./deploy.sh dev                     # Deploy all modules to dev"
  echo "  ./deploy.sh dev 01-network          # Deploy single module to dev"
  echo "  ./deploy.sh dev 01-network --init   # Init and deploy single module to dev"
  echo "  ./deploy.sh prod --init             # Init and deploy all modules to prod"
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
if [ -n "$TARGET_MODULE" ]; then
  if [ ! -d "$TARGET_MODULE" ]; then
    echo "Error: Module directory '$TARGET_MODULE' not found."
    exit 1
  fi
  MODULES=("$TARGET_MODULE")
else
  # Note: 08-cognito should come before 03-ebs-v1 because the Beanstalk role policy
  # references the Cognito user pool ARN from the Cognito stack.
  MODULES=(01-network 02-db 03-bastion 08-cognito 03-ebs-v1 04-alb 05-ssm-access 07-cicd 10-s3 15-ebs-conf)
fi

for DIR in "${MODULES[@]}"; do
  # Determine backend config file (prefer environment-specific if available)
  BACKEND_CONFIG="../backend.config"
  if [ -f "backend.${ENV}.config" ]; then
    BACKEND_CONFIG="../backend.${ENV}.config"
  fi

  # Only init if --init flag is set OR if .terraform doesn't exist
  if [ "$INIT" = true ] || [ ! -d "$DIR/.terraform" ]; then
    echo "Initializing $DIR..."
    terraform -chdir=$DIR init -reconfigure -backend-config="$BACKEND_CONFIG" \
      -backend-config="key=$ENV/$DIR/terraform.tfstate"
  fi

  TFVARS_FILENAME="${DIR}.tfvars"
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
