#!/bin/bash
set -e

ENV=$1
LOCK_FILE="/tmp/terraform-destroy-${ENV}.lock"

if [ -z "$ENV" ]; then
  echo "Usage: ./destroy.sh <dev|prod>"
  exit 1
fi

if [ "$ENV" != "dev" ] && [ "$ENV" != "prod" ]; then
  echo "Error: Environment must be 'dev' or 'prod'"
  exit 1
fi

# Check for lock file
if [ -f "$LOCK_FILE" ]; then
  echo "Error: Another destroy operation for $ENV is already running."
  echo "If this is incorrect, remove: $LOCK_FILE"
  exit 1
fi

# Create lock file
echo $$ > "$LOCK_FILE"
trap "rm -f $LOCK_FILE" EXIT

echo "WARNING: This will destroy the entire $ENV environment!"
echo "This includes:"
echo "  - SSM Access IAM resources"
echo "  - Application Load Balancer"
echo "  - Elastic Beanstalk application"
echo "  - Bastion EC2 instance"
echo "  - RDS Aurora Database (all data will be lost)"
echo "  - VPC and Network resources"
echo ""
read -p "Are you sure you want to destroy $ENV? (type 'yes' to confirm): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
  echo "Destroy cancelled."
  exit 0
fi

echo "Destroying $ENV environment..."

terraform -chdir=08-cognito destroy -var-file=../$ENV.tfvars -auto-approve
terraform -chdir=01-network destroy -var-file=../$ENV.tfvars -auto-approve

echo "$ENV environment destroyed successfully!"
