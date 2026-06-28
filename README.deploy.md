
## Beanstalk v2 (gc-api) Deployment (prod only)

1. Deploy 01-network for prod:
  ```
  cd 01-network
  terraform init -backend-config="key=prod/network/terraform.tfstate"
  terraform apply -var-file=prod.tfvars
  ```

2. Deploy 03-app-ebs-v2 for prod:
  ```
  cd ../03-app-ebs-v2
  terraform init -backend-config="key=prod/app-ebs-v2/terraform.tfstate"
  terraform apply -var-file=prod.tfvars \
    -var="aws_region=us-west-1" \
    -var="alb_sg_id=$(terraform -chdir=../04-load-balancer output -raw alb_sg_id)"
  ```

3. Deploy 04-load-balancer for prod (after 03-app-ebs-v2):
  ```
  cd ../04-load-balancer
  terraform init -backend-config="key=prod/load-balancer/terraform.tfstate"
  terraform apply -var-file=prod.tfvars
  ```

* The ALB will route /v2/* traffic to the Beanstalk gc-api environment (v2 target group).
* The Beanstalk environment is private, only accessible via the ALB.
# Deployment Guide

## Deploy Infrastructure

**Create S3 bucket for Terraform state (one-time setup):****
```bash
bucketName=gc-terraform-state-c8f7ewhysy5w
aws s3 mb s3://${bucketName} 
aws s3api put-bucket-versioning --bucket ${bucketName} --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption --bucket ${bucketName} \
  --server-side-encryption-configuration '{
    "Rules": [{ "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" } }]
  }'
```

**First time deployment:**
```bash
./deploy.sh dev --init
```

**Subsequent deployments:**
```bash
./deploy.sh dev
```

**Production deployment:**
```bash
./deploy.sh prod --init  # First time
./deploy.sh prod         # Updates
```

## Destroy Infrastructure

```bash
./destroy.sh dev
./destroy.sh prod
```

## When to Use --init Flag

Use `--init` flag when:
- First time deploying
- Backend configuration changes
- Provider version updates
- Adding new modules

Skip `--init` for regular updates to save time.

## Deployment Order

The scripts deploy in this order:
1. Network (VPC, subnets, NAT gateway)
2. Database (RDS Aurora)
3. Application (EC2 instances, ASG)
4. Load Balancer (ALB)
5. IAM SSM Access

Destroy happens in reverse order.

## Deployment by Environment

### Dev/Prod Environment
set environment variable to 'dev'
```bash
export ENV=dev
## export ENV=prod
```  
when switching from dev to prod, or the other way, run terraform init first and plan
```bash

 ```


Deploy in this order:

**1. Network (VPC, Subnets, Bastion)**
```bash
DIR=01-network;ENV=dev
terraform -chdir=$DIR init -reconfigure -config="key=${ENV}/network/terraform.tfstate"
terraform -chdir=$DIR plan -var-file=${ENV}.tfvars
terraform -chdir=$DIR apply -var-file=${ENV}.tfvars -auto-approve
cd ..
```

**2. Database (RDS Aurora)**
```bash
DIR=02-db
# terraform init -reconfigure -backend-config="key=${ENV}/app-ec2/terraform.tfstate"
terraform -chdir=$DIR init -reconfigure -backend-config=../backend.config -backend-config="key=${ENV}/db/terraform.tfstate"
terraform -chdir=$DIR plan -backend-config="key=${ENV}/db/terraform.tfstate" var-file=${ENV}.tfvars
terraform -chdir=$DIR apply -var-file=${ENV}.tfvars -auto-approve
cd ..
```

**3. Application (EC2 Instances)**
```bash
cd 03-app-ec2-v1
terraform init -reconfigure -backend-config="key=${ENV}/app-ec2/terraform.tfstate"
terraform init -backend-config="key=${ENV}/app-ec2/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars -auto-approve
cd ..
```

**4. Load Balancer (ALB)**
```bash
cd 04-load-balancer
terraform init -backend-config="key=${ENV}/load-balancer/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars -auto-approve
cd ..
```

**5. IAM SSM Access Control**
```bash
cd 05-iam-ssm-access
terraform init -backend-config="key=${ENV}/iam-ssm-access/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars -auto-approve
cd ..
```

**6. EKS Cluster (Optional)**
```bash
cd 06-app-eks-v2
terraform init -backend-config="key=${ENV}/app-eks/terraform.tfstate"
terraform plan -var-file=${ENV}.tfvars
terraform apply -var-file=${ENV}.tfvars
cd ..
```



## Cost Estimates

**Dev Environment (~$132-140/month):**
- RDS Aurora db.t3.small: ~$36.50/month
- NAT Gateway: ~$32/month
- ALB: ~$16/month
- EC2 t3.micro: ~$7.50/month
- Storage & misc: ~$3/month

**To minimize costs:**
- Run `./destroy.sh dev` when not in use
- S3 state buckets cost ~$0.02/month (keep these)
