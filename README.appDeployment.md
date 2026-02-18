## Application Deployment with Auto Scaling Group

### Prerequisites

**Create S3 bucket for app deployment (one-time setup):****
```bash
bucketName=gc-app-deployments-c8f7ewhysy5a
aws s3 mb s3://${bucketName} 
aws s3api put-bucket-versioning --bucket ${bucketName} --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket ${bucketName} \
  --server-side-encryption-configuration '{
    "Rules": [{ "ApplyServerSideEncryptionByDefault": { "SSEAlgorithm": "AES256" } }]
  }'
```
```

### Initial Deployment

Upload your JAR file to S3:
```bash
# For dev environment
aws s3 cp target/app.jar s3://${bucketName}$/dev/app.jar

# For prod environment
aws s3 cp target/app.jar s3://gc-app-deployments/prod/app.jar
```
### Updating the Application

**Option 1: Rolling Update (Recommended)**
```bash
# 1. Upload new JAR to S3
aws s3 cp target/app.jar s3://${bucketName}/dev/app.jar

# 2. Trigger instance refresh (zero-downtime rolling replacement)
aws autoscaling start-instance-refresh \
  --auto-scaling-group-name dev-app-asg \
  --preferences MinHealthyPercentage=50
```

**Option 2: Update Launch Template**
```bash
# 1. Upload new JAR to S3
aws s3 cp target/app.jar s3://gc-app-deployments/dev/app.jar

# 2. Update launch template (creates new version)
terraform apply -var-file=dev.tfvars

# 3. Manually terminate instances one by one (ASG will launch new ones)
```

### Monitoring

**Check ASG status:**
```bash
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names dev-app-asg
```

**View instance refresh status:**
```bash
aws autoscaling describe-instance-refreshes --auto-scaling-group-name dev-app-asg
```

**View application logs:**
```bash
# CloudWatch Logs
aws logs tail /aws/ec2/dev-api --follow
```

### Scaling

**Manual scaling:**
```bash
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name dev-app-asg \
  --desired-capacity 3
```

**Or update tfvars and apply:**
```hcl
desired_capacity = 3
```
