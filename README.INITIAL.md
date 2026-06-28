# Initial Setup Guide

## Enable AWS API Audit Tracking

Enable CloudTrail to audit all AWS API commands:

**1. Create KMS key for S3 encryption:**
```bash
KEY_ID=$(aws kms create-key --description "CloudTrail S3 encryption key" --query 'KeyMetadata.KeyId' --output text)
aws kms create-alias --alias-name alias/cloudtrail-S3-key --target-key-id ${KEY_ID}
```

**2. Create S3 bucket for CloudTrail logs with KMS encryption:**
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME=cloudtrail-${ACCOUNT_ID}
aws s3 mb s3://${BUCKET_NAME}

# Enable default encryption with KMS
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "aws:kms",
        "KMSMasterKeyID": "arn:aws:kms:'$(aws configure get region)':'${ACCOUNT_ID}':key/'${KEY_ID}'"
      },
      "BucketKeyEnabled": true
    }]
  }'

# Add bucket policy to allow CloudTrail to use the KMS key
aws s3api put-bucket-policy --bucket ${BUCKET_NAME} --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::'${BUCKET_NAME}'"
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::'${BUCKET_NAME}'/AWSLogs/'${ACCOUNT_ID}'/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}'

# Add KMS key policy to allow CloudTrail
aws kms put-key-policy --key-id ${KEY_ID} --policy-name default --policy '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM policies",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::'${ACCOUNT_ID}':root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow CloudTrail to encrypt logs",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": [
        "kms:GenerateDataKey",
        "kms:DecryptDataKey"
      ],
      "Resource": "*"
    }
  ]
}'
```

**3. Create CloudTrail:**
```bash
aws cloudtrail create-trail --name cloudtrail-${ACCOUNT_ID} --s3-bucket-name ${BUCKET_NAME}
```

**4. Enable logging on all regions:**
```bash
aws cloudtrail start-logging --trail-name cloudtrail-${ACCOUNT_ID}
```

**4. Configure event selectors to capture all API calls:**
```bash
aws cloudtrail put-event-selectors --trail-name cloudtrail-${ACCOUNT_ID} --event-selectors '[{"ReadWriteType":"All","IncludeManagementEvents":true}]'
```

**5. Verify CloudTrail is enabled:**
```bash
aws cloudtrail describe-trails --trail-name cloudtrail-${ACCOUNT_ID}
aws cloudtrail get-trail-status --name cloudtrail-${ACCOUNT_ID}
```

All AWS API calls will now be logged to S3 for audit purposes.

## Setup Terraform State Storage

Create S3 bucket and KMS key for Terraform state:

**1. Create CMK for S3 encryption:**
```bash
CMK_S3_ID=$(aws kms create-key --description "encryption key for S3 bucket" --query 'KeyMetadata.KeyId' --output text)
aws kms create-alias --alias-name alias/CMK-S3-key --target-key-id ${CMK_S3_ID}
```

**2. Create S3 bucket for Terraform state with versioning and KMS encryption:**
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET=gc-terraform-state-c8f7ewhysy5w
aws s3 mb s3://${STATE_BUCKET}
aws s3api put-bucket-versioning --bucket ${STATE_BUCKET} --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket ${STATE_BUCKET} --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"aws:kms","KMSMasterKeyID":"arn:aws:kms:'$(aws configure get region)':'${ACCOUNT_ID}':key/'${CMK_S3_ID}'"},"BucketKeyEnabled":true}]}'
```

**3. Store bucket name in backend.config:**
```bash
echo "bucket = ${STATE_BUCKET}" >> backend.config
```

Use this bucket name when initializing Terraform modules for the `deploy.sh` script.

## Configure Terraform Variables

Root-level tfvars files allow environment-specific configuration:

**1. Create .env file from template:**
```bash
cp .env.example .env
```

**2. Edit .env with your sensitive values:**
```bash
# Edit .env and set database password, API keys, etc.
nano .env
```

**3. Source .env before deploying:**
```bash
source .env
./deploy.sh dev
```

**File structure:**
- `dev.tfvars` - Development environment variables (non-sensitive)
- `prod.tfvars` - Production environment variables (non-sensitive)
- `.env.example` - Template for sensitive variables (committed to git)
- `.env` - Actual sensitive values (NEVER committed, add to .gitignore)

**Key points:**
- `.tfvars` files (dev/prod) contain non-sensitive config and can be committed
- `.env` file contains sensitive data (database passwords, API keys) - never commit
- Use `TF_VAR_` prefix in .env for Terraform variables
- Source .env before running deploy.sh to load sensitive variables
