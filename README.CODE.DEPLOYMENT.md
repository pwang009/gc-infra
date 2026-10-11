# Elastic Beanstalk Code Deployment Guide (Python API)

This guide describes how to deploy application code to AWS Elastic Beanstalk (`gc-api-dev` and `gc-api-prod`) using zero-downtime **Immutable (Blue/Green)** deployments.

---

## Architecture Overview

* **Application:** Python 3.12 REST API (`gc-api`)
* **Platform:** 64-bit Amazon Linux 2023 running Python 3.12
* **Environments:**
  * **Dev:** `gc-api-dev`
  * **Prod:** `gc-api-prod`
* **Region:** `us-west-2`
* **Deployment Policy:** `Immutable` (automated Blue/Green instance rotation with zero downtime and automatic rollback)

---

## 1. Prerequisites

1. **AWS CLI** installed and configured with credentials for account `339087217430` (or target AWS account).
2. S3 deployment bucket available:
   * **Prod:** `s3://gc-terraform-state-c8f7ewhysy5v/versions/`
   * **Dev:** `s3://gc-terraform-state-c8f7ewhysy5w/versions/`
3. Proper application files in your API project repository:
   * `requirements.txt` (Python dependencies)
   * `application.py` or `Procfile` (specifying entrypoint, e.g. `web: uvicorn main:app --host 0.0.0.0 --port 5000` or `web: gunicorn application:app`)
   * Health check endpoint answering `GET /health` with HTTP 200

---

## 2. Python Application Structure

Ensure your application root contains:

```
my-python-api/
├── Procfile                    # web: uvicorn main:app --host 0.0.0.0 --port $PORT
├── requirements.txt            # Python dependencies (including aws-xray-sdk)
├── application.py (or main.py) # Application entrypoint
├── .ebextensions/              # Optional Beanstalk configurations
│   └── xray-daemon.config
└── app/                        # Application source code
```

---

## 3. Step-by-Step Code Deployment

### Step 1: Package the Application

From your application code repository root:

```bash
# Define version label
VERSION_LABEL="v$(date +%Y%m%d%H%M%S)"
# Example: VERSION_LABEL="v1.0.1"

# Create deployment zip bundle (excluding git, venv, and cache)
zip -r "deploy-${VERSION_LABEL}.zip" . \
  -x "*.git*" "*venv/*" "*.venv/*" "*__pycache__*" "*.pytest_cache*" "*.env*"
```

---

### Step 2: Upload Source Bundle to S3

#### For Production:
```bash
aws s3 cp "deploy-${VERSION_LABEL}.zip" \
  "s3://gc-terraform-state-c8f7ewhysy5v/versions/gc-api-${VERSION_LABEL}.zip" \
  --region us-west-2
```

#### For Development:
```bash
aws s3 cp "deploy-${VERSION_LABEL}.zip" \
  "s3://gc-terraform-state-c8f7ewhysy5w/versions/gc-api-${VERSION_LABEL}.zip" \
  --region us-west-2
```

---

### Step 3: Create an Application Version

```bash
aws elasticbeanstalk create-application-version \
  --region us-west-2 \
  --application-name "gc-api" \
  --version-label "${VERSION_LABEL}" \
  --source-bundle S3Bucket="gc-terraform-state-c8f7ewhysy5v",S3Key="versions/gc-api-${VERSION_LABEL}.zip" \
  --description "Deployment ${VERSION_LABEL}"
```

*(For dev, change `S3Bucket` to `gc-terraform-state-c8f7ewhysy5w`)*

---

### Step 4: Deploy to Environment

#### For Production (`gc-api-prod`):
```bash
aws elasticbeanstalk update-environment \
  --region us-west-2 \
  --environment-name "gc-api-prod" \
  --version-label "${VERSION_LABEL}"
```

#### For Development (`gc-api-dev`):
```bash
aws elasticbeanstalk update-environment \
  --region us-west-2 \
  --environment-name "gc-api-dev" \
  --version-label "${VERSION_LABEL}"
```

---

## 4. Automated One-Command Deployment Script

You can save this script as `deploy-app.sh` in your API repository:

```bash
#!/bin/bash
set -e

ENV=${1:-dev}
VERSION=${2:-"v$(date +%Y%m%d%H%M%S)"}
REGION="us-west-2"
APP_NAME="gc-api"
ENV_NAME="gc-api-${ENV}"

if [ "$ENV" == "prod" ]; then
  S3_BUCKET="gc-terraform-state-c8f7ewhysy5v"
elif [ "$ENV" == "dev" ]; then
  S3_BUCKET="gc-terraform-state-c8f7ewhysy5w"
else
  echo "Usage: ./deploy-app.sh <dev|prod> [version_label]"
  exit 1
fi

ZIP_FILE="deploy-${VERSION}.zip"
S3_KEY="versions/${ZIP_FILE}"

echo "==> Packaging application ($VERSION)..."
zip -r "$ZIP_FILE" . -x "*.git*" "*venv/*" "*.venv/*" "*__pycache__*" "*.pytest_cache*" "*.env*"

echo "==> Uploading package to s3://$S3_BUCKET/$S3_KEY..."
aws s3 cp "$ZIP_FILE" "s3://$S3_BUCKET/$S3_KEY" --region "$REGION"
rm -f "$ZIP_FILE"

echo "==> Creating Beanstalk application version..."
aws elasticbeanstalk create-application-version \
  --region "$REGION" \
  --application-name "$APP_NAME" \
  --version-label "$VERSION" \
  --source-bundle S3Bucket="$S3_BUCKET",S3Key="$S3_KEY" \
  --description "Deployed $(date)"

echo "==> Updating environment $ENV_NAME with $VERSION (Immutable Blue/Green)..."
aws elasticbeanstalk update-environment \
  --region "$REGION" \
  --environment-name "$ENV_NAME" \
  --version-label "$VERSION"

echo "==> Deployment initiated successfully!"
echo "Check status with: aws elasticbeanstalk describe-environments --region $REGION --environment-names $ENV_NAME"
```

**Usage:**
```bash
chmod +x deploy-app.sh
./deploy-app.sh dev             # Deploys to dev with auto-generated timestamp version
./deploy-app.sh prod v1.2.0     # Deploys v1.2.0 to prod
```

---

## 5. How Immutable Blue/Green Deployment Works

Because `DeploymentPolicy = "Immutable"` is configured:

1. **New Temporary Auto Scaling Group (Green):** Elastic Beanstalk launches a new set of EC2 instances with the new code bundle.
2. **Health Check Validation:** The new instances are placed behind the load balancer and evaluated against `GET /health`.
3. **Traffic Cutover:** Once verified healthy, live traffic shifts to the new instances.
4. **Old Instance Cleanup (Blue):** The old instances are terminated.
5. **Automatic Rollback:** If the new instances fail health checks, Beanstalk automatically deletes the temporary instances without affecting live traffic.

---

## 6. Monitoring & Troubleshooting

### Monitor Deployment Status
```bash
# Check environment health & status
aws elasticbeanstalk describe-environments \
  --region us-west-2 \
  --environment-names "gc-api-prod" \
  --query "Environments[*].[EnvironmentName,Status,Health,VersionLabel]" \
  --output table

# Stream environment events (deployment logs)
aws elasticbeanstalk describe-events \
  --region us-west-2 \
  --environment-name "gc-api-prod" \
  --max-items 15 \
  --query "Events[*].[EventDate,Severity,Message]" \
  --output table
```

### View Application Logs
```bash
# Stream CloudWatch logs for Beanstalk
aws logs tail /aws/elasticbeanstalk/gc-api-prod/var/log/eb-engine.log --follow
```

### Quick Rollback to Previous Version
If you ever need to rollback to an earlier version:
```bash
aws elasticbeanstalk update-environment \
  --region us-west-2 \
  --environment-name "gc-api-prod" \
  --version-label "v1.0.0"   # Specify previous version label
```
