## network section notes

### Prerequisites

**Create S3 bucket for Terraform state (one-time setup):**
```bash
aws s3 mb s3://gc-terraform-state-c8f7ewhysy5a --region us-west-1

aws s3api put-bucket-versioning \
  --bucket gc-terraform-state-c8f7ewhysy5a \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket gc-terraform-state-c8f7ewhysy5a \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

### Terraform Backend Initialization

**Dev Environment:**
```bash
terraform init -backend-config="key=dev/network/terraform.tfstate"
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

**Prod Environment:**
```bash
terraform init -backend-config="key=prod/network/terraform.tfstate"
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

### Accessing EC2 Instances via SSM

**List instances:**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],PrivateIpAddress,State.Name]' \
  --output table
```

**Connect to instance:**
```bash
aws ssm start-session --target i-xxxxxxxxx
```

**Port forwarding (for debugging):**
```bash
aws ssm start-session \
  --target i-xxxxxxxxx \
  --document-name AWS-StartPortForwardingSession \
  --parameters "portNumber=8080,localPortNumber=8080"
```

### Connecting to RDS from local machine

**Via SSM port forwarding through EC2:**
```bash
aws ssm start-session \
  --target i-xxxxxx \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{"portNumber":["5432"],"localPortNumber":["5432"],"host":["your-aurora-endpoint.com"]}'
```