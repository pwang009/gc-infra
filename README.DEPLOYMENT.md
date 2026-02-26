# GC API Production Stack - Deployment Guide

## Prerequisites

1. AWS CLI v2 configured with credentials
2. Terraform v1.5+
3. S3 bucket for state: `gc-terraform-state-c8f7ewhysy5a`
4. DynamoDB table for locks: `terraform-locks` (optional but recommended)

## One-Time Setup

### Create S3 Bucket for Terraform State

```bash
BUCKET_NAME=gc-terraform-state-c8f7ewhysy5a

# Create bucket
aws s3 mb s3://${BUCKET_NAME}

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket ${BUCKET_NAME} \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket ${BUCKET_NAME} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Block public access
aws s3api put-public-access-block \
  --bucket ${BUCKET_NAME} \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### Create DynamoDB Table for Locks (Optional)

```bash
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

---

## Deployment Sequence

### Environment Setup

```bash
# Choose environment (dev or prod)
export ENV=prod
export AWS_REGION=us-west-1
```

### 1. Network Infrastructure (01-network)

**First deployment (with --init):**
```bash
cd 01-network
terraform init -backend-config="key=${ENV}/network/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars
cd ..
```

**Subsequent deployments:**
```bash
cd 01-network
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars
cd ..
```

**Outputs to verify:**
```bash
cd 01-network
terraform output
# Should show: vpc_id, public_subnets, private_subnets, etc.
cd ..
```

### 2. Database (RDS Aurora) (02-db)

```bash
cd 02-db
terraform init -backend-config="key=${ENV}/db/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars
cd ..
```

**Verify:**
```bash
aws rds describe-db-clusters \
  --query 'DBClusters[0].[DBClusterIdentifier,Status,Endpoint]'
```

---

### 3. Bastion + VPN Gateway (03-bastion)

**Before deploying, request ACM certificate for VPN:**

```bash
# Request certificate for vpn.abc.com
aws acm request-certificate \
  --domain-name vpn.abc.com \
  --validation-method DNS \
  --region us-west-1

# Note the certificate ARN (format: arn:aws:acm:...)
# Then validate via GoDaddy DNS (see README.CERTIFICATES.md)
# Wait for validation to complete
```

**Deploy bastion:**

```bash
cd 03-bastion

# Ensure certificate_arn is set in prod.tfvars/dev.tfvars
# certificate_arn = "arn:aws:acm:us-west-1:ACCOUNT_ID:certificate/ID"

terraform init -backend-config="key=${ENV}/bastion/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars
cd ..
```

**Verify:**
```bash
# Get NLB DNS name
cd 03-bastion
terraform output nlb_dns_name
cd ..

# Create Route 53 CNAME in GoDaddy: vpn.abc.com → <NLB_DNS_NAME>
```

**On first boot, retrieve VPN client config:**
```bash
# Get bastion instance ID
BASTION_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=gc-bastion-${ENV}" \
              "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

# SSH into bastion (via SSM or direct)
aws ssm start-session --target ${BASTION_ID}

# From bastion shell:
cat /etc/openvpn/client.ovpn

# Copy output and save locally as bastion-client.ovpn
```

---

### 4. Elastic Beanstalk - v1 (03-ebs-v1)

```bash
cd 03-ebs-v1
terraform init -backend-config="key=${ENV}/app-ebs-v1/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars

# Capture the ASG name from output
terraform output beanstalk_asg_names
cd ..
```

**Initial app deployment:**
```bash
# Build your Spring Boot app locally
mvn clean package

# Deploy to S3 and create version
aws s3 cp target/app.jar s3://gc-app-deployments-c8f7ewhysy5a/${ENV}/app-v1.jar

# Create application version in Beanstalk
aws elasticbeanstalk create-app-version \
  --application-name gc-api \
  --version-label v1-initial \
  --source-bundle S3Bucket=gc-app-deployments-c8f7ewhysy5a,S3Key=${ENV}/app-v1.jar

# Update environment to use this version
aws elasticbeanstalk update-environment \
  --application-name gc-api \
  --environment-name gc-api-${ENV} \
  --version-label v1-initial
```

---

### 5. Elastic Beanstalk - v2 (03-ebs-v2)

Same process as v1, but for a different version endpoint:

```bash
cd 03-ebs-v2
terraform init -backend-config="key=${ENV}/app-ebs-v2/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars
cd ..
```

---

### 6. Application Load Balancer (04-alb)

**Before deploying, request ACM certificate for ALB:**

```bash
# Request certificate for api.abc.com
aws acm request-certificate \
  --domain-name api.abc.com \
  --validation-method DNS \
  --region us-west-1

# Validate via GoDaddy (see README.CERTIFICATES.md)
# Wait for validation to complete
```

**Deploy ALB:**

```bash
cd 04-alb

# Ensure certificate ARN is set in prod.tfvars/dev.tfvars
# ssl_certificate_arn = "arn:aws:acm:us-west-1:ACCOUNT_ID:certificate/ID"

terraform init -backend-config="key=${ENV}/alb/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars

# Get ALB DNS name
terraform output alb_dns_name

cd ..
```

**Create Route 53 CNAME in GoDaddy:** `api.abc.com` → `<ALB_DNS_NAME>`

---

### 7. SSM Access Control (05-ssm-access)

```bash
cd 05-ssm-access
terraform init -backend-config="key=${ENV}/ssm-access/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars
cd ..
```

This grants bastion access via Systems Manager to authorized IAM users.

---

### 8. X-Ray Monitoring (06-x-ray)

```bash
cd 06-x-ray
terraform init -backend-config="key=${ENV}/x-ray/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars

# Get X-Ray policy ARN for attachment to Beanstalk role
terraform output xray_policy_arn
cd ..
```

Then attach the policy to Beanstalk EC2 role (see 06-x-ray/README.md for details).

---

## Post-Deployment Checklist

- [ ] VPC created with correct CIDR ranges (10.66.0.0/16)
- [ ] RDS Aurora cluster available and accepting connections
- [ ] Bastion running with OpenVPN on port 1194/UDP
- [ ] NLB DNS name resolves to bastion (vpn.abc.com)
- [ ] ALB DNS name resolves and routes `/v1/*` and `/v2/*` correctly
- [ ] Beanstalk instances healthy (check target group health checks)
- [ ] ACM certificates issued and not expiring (auto-renewal enabled)
- [ ] SSM Session Manager works for bastion access
- [ ] X-Ray sampling rule created (check console)
- [ ] CloudWatch logs flowing from ALB and Beanstalk

---

## Testing Deployment

```bash
# Test ALB health
curl -I https://api.abc.com/v1/greetings

# Test v1 API
curl -X GET https://api.abc.com/v1/greetings?name=Test

# Test v2 API
curl -X GET https://api.abc.com/v2/greetings?name=Test

# Connect to VPN
openvpn --config bastion-client.ovpn

# Test database from bastion
aws ssm start-session --target <BASTION_ID>
# mysql -h 10.66.20.x -u appUser -p appProdDB

# View ALB access logs in S3
aws s3 ls s3://gc-alb-logs-bucket/prod/

# Check X-Ray service map
# AWS Console → X-Ray → Service Map
```

---

## Destroying Infrastructure

**Destroy in reverse order:**

```bash
export ENV=prod

# 1. X-Ray
cd 06-x-ray && terraform destroy -var-file=${ENV}.tfvars && cd ..

# 2. SSM Access
cd 05-ssm-access && terraform destroy -var-file=${ENV}.tfvars && cd ..

# 3. ALB
cd 04-alb && terraform destroy -var-file=${ENV}.tfvars && cd ..

# 4. Beanstalk v2
cd 03-ebs-v2 && terraform destroy -var-file=${ENV}.tfvars && cd ..

# 5. Beanstalk v1
cd 03-ebs-v1 && terraform destroy -var-file=${ENV}.tfvars && cd ..

# 6. Bastion
cd 03-bastion && terraform destroy -var-file=${ENV}.tfvars && cd ..

# 7. Database
cd 02-db && terraform destroy -var-file=${ENV}.tfvars && cd ..

# 8. Network (last)
cd 01-network && terraform destroy -var-file=${ENV}.tfvars && cd ..

echo "Infrastructure destroyed. S3 state bucket remains (for recovery)."
```

---

## Troubleshooting Deployments

### State Lock Issues

```bash
# List locks
aws dynamodb scan --table-name terraform-locks

# Force unlock (dangerous, use only if lock is orphaned)
terraform force-unlock <LOCK_ID>
```

### Module Dependencies

If deploy fails because of missing outputs:

```bash
# Manually run dependencies first
cd 01-network && terraform apply && cd ..
cd 02-db && terraform apply && cd ..

# Then retry the failing module
cd 03-ebs-v1 && terraform apply && cd ..
```

### ACM Certificate Issues

```bash
# List pending certificates
aws acm list-certificates --certificate-statuses PENDING_VALIDATION

# Check validation status
aws acm describe-certificate --certificate-arn arn:aws:acm:...
```

---

## Scaling & Updates

### Scale ASG

```bash
# Increase desired capacity
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name gc-api-prod-asg \
  --desired-capacity 4
```

### Update Beanstalk App

```bash
# Upload new JAR
aws s3 cp target/app.jar s3://gc-app-deployments-c8f7ewhysy5a/prod/app-v1.2.jar

# Create version
aws elasticbeanstalk create-app-version \
  --application-name gc-api \
  --version-label v1.2 \
  --source-bundle S3Bucket=gc-app-deployments-c8f7ewhysy5a,S3Key=prod/app-v1.2.jar

# Deploy
aws elasticbeanstalk update-environment \
  --application-name gc-api \
  --environment-name gc-api-prod \
  --version-label v1.2
```

---

## Cost Optimization

- **Dev**: Destroy when idle (`./destroy.sh dev`)
- **Prod**: Use reserved instances for 20-30% savings
- **RDS**: Switch to db.t3.small in prod, t3.micro in dev
- **X-Ray**: Reduce sampling rate from 0.5 to 0.1 in dev
- **ALB**: Consolidate multiple ALBs into one if possible
