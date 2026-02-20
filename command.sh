## create s3 bucket
aws s3api put-bucket-versioning \
  --bucket gc-terraform-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket gc-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

aws s3api create-bucket \
  --bucket gc-alb-access-logs \
  --region us-west-1 \
  --create-bucket-configuration LocationConstraint=us-west-1
  
aws s3api put-bucket-versioning \
--bucket gc-alb-access-logs \
--versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket gc-alb-access-logs \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

## create a key pair
keyPairName=gconnex-ec2
aws ec2 create-key-pair --key-name ${keyPairName} --query 'KeyMaterial' --output text > ${keyPairName}.pem


## shut down everything 
# 5. IAM SSM Access (free, but clean up)
cd 05-iam-ssm-access
terraform destroy -var-file=dev.tfvars -auto-approve
cd ..

# 4. Load Balancer (~$16/month)
cd 04-load-balancer
terraform destroy -var-file=dev.tfvars -auto-approve
cd ..

# 3. EC2 Instances (~$7.50/month)
cd 03-app-ec2-v1
terraform destroy -var-file=dev.tfvars -auto-approve
cd ..

# 2. RDS Aurora (~$75/month) - BIGGEST COST
cd 02-db
terraform destroy -var-file=dev.tfvars -auto-approve
cd ..

# 1. Network/NAT Gateway (~$32/month)
cd 01-network
terraform destroy -var-file=dev.tfvars -auto-approve
cd ..




## Set PEM file permissions
chmod 400 ${keyPairName}.pem
