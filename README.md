# PROJECT

## Requirement

1. deploying a 3 tier rest api 
2. vpc (Production)
    - 2 public subnet
    - 2 private subnet (ec2)   
    - 2 private subnet (rds)
3. EC2
    - 2 ec2 to start with
    - ec2 are within a asg
4. rds
    - Auroua mySQL in private subnet (see README.md for access)
    - use Auroua proxy

5. load balancer
    - pointing v1 to ec2 based api, like api.abc.com/vi

6. Terraform
    - use terraform to build infrastructure
    - use s3 to store terraform state

7. Code Deployment
    - repository: github
    - when code checked in, github action builds jar file, store it to codeartifact and deploy to dev env

## Find public ip
```bash
dig +short myip.opendns.com @resolver1.opendns.com
```

## Prerequisites

**Install AWS Session Manager Plugin:**

*macOS:*
```bash
brew install --cask session-manager-plugin
```

*Linux:*
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
```

*Windows:*
Download and install from: https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe

**Verify installation:**
```bash
session-manager-plugin
```
## Accessing EC2 Instances

### Via SSM Session Manager

**List instances:**
```bash
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0],PrivateIpAddress]' \
  --output table
```

**Connect to instance:**
```bash
instanceID=$(aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=${ENV}" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[0].InstanceId | [0]' \
  --output text)
aws ssm start-session --target ${instanceID}
```

**Port forwarding (for database):**
```bash
aws ssm start-session \
  --target ${instanceID} \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{
    "host":["prod-aurora-cluster.cluster-cdqmgwiqilow.us-west-1.rds.amazonaws.com"],
    "portNumber":["3306"],
    "localPortNumber":["3306"]
  }'
```

### Deploying Application JAR

**Manual deployment via S3:**
```bash
# 1. Upload JAR to S3
aws s3 cp target/app.jar s3://gc-app-deployments-c8f7ewhysy5a/dev/app.jar

# 2. Connect to EC2 via SSM
aws ssm start-session --target i-0f96e1783a1b8bda5

# 3. On EC2, download from S3 and restart service
sudo aws s3 cp s3://gc-app-deployments-c8f7ewhysy5a/dev/app.jar /opt/app/app.jar
sudo chown ec2-user:ec2-user /opt/app/app.jar
sudo systemctl restart api

# 4. Verify service is running
sudo systemctl status api
curl http://localhost:8080/greeting?name=Tony

# 5. verify database
mysql -h prod-aurora-cluster.cluster-cdqmgwiqilow.us-west-1.rds.amazonaws.com -u admin -p appdb
```

### Managing SSM Access

**Add IAM user to SSM access group:**
```bash
aws iam add-user-to-group \
  --user-name john.doe \
  --group-name dev-ssm-users
```

**Update allowed IPs:**
Edit `05-iam-ssm-access/dev.tfvars`:
```hcl
allowed_source_ips = [
  "70.181.86.188/32",
  "203.0.113.0/24"
]
```

Then apply:
```bash
cd 06-iam-ssm-access
terraform apply -var-file=dev.tfvars -auto-approve
cd ..
```