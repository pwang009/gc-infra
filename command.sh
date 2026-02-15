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

## create a key pair
keyPairName=gconnex-ec2
aws ec2 create-key-pair --key-name ${keyPairName} --query 'KeyMaterial' --output text > ${keyPairName}.pem


## Set PEM file permissions
chmod 400 ${keyPairName}.pem
