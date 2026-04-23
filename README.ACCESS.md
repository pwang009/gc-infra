# GC API Production Stack - Access & Connectivity

## Overview

This document covers all methods to access resources in the stack: bastion via SSM and database via port forwarding (recommended secure approach).

## Prerequisites

1. **AWS CLI** v2 installed
2. **Session Manager Plugin** installed
3. **MySQL Client** (optional, for direct DB queries)
4. IAM user with appropriate permissions (see below)

### Install Session Manager Plugin

**macOS:**
```bash
brew install --cask session-manager-plugin
```

**Linux:**
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
```

**Windows:**
Download and install from: https://s3.amazonaws.com/session-manager-downloads/plugin/latest/windows/SessionManagerPluginSetup.exe

**Verify:**
```bash
session-manager-plugin
```

---

## Method 1: SSM Session Manager (Bastion Shell Access)

### Quick Connect

```bash
# Set environment
export ENV=prod  # or dev

# Get bastion instance ID
BASTION_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=gc-bastion-${ENV}" \
              "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

# Start interactive session
aws ssm start-session --target ${BASTION_ID}
```

### Once Connected to Bastion

```bash
# Check system health
uptime
df -h

# View OpenVPN status
sudo systemctl status openvpn-server@server

# View X-Ray daemon (if enabled)
sudo systemctl status xray

# List available databases via MySQL in bastion
mysql -h <RDS_ENDPOINT> -u appUser -p appProdDB
```

---

## Method 2: Port Forwarding to RDS (via Bastion)

### Setup Port Forwarding 

```bash
# Set environment
export ENV=prod
export BASTION_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=gc-bastion-${ENV}" \
              "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

# Start port forwarding session
aws ssm start-session --target ${BASTION_ID} \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters '{
    "host":["prod-aurora-cluster.cluster-cdqmgwiqilow.us-west-1.rds.amazonaws.com"],
    "portNumber":["3306"],
    "localPortNumber":["3306"]
  }'
```

### Connect to Database via Local Port

**In another terminal:**
```bash
# Connect using MySQL client
mysql -h 127.0.0.1 -u appUser -p appProdDB

# Or for admin user
mysql -h 127.0.0.1 -u admin -p
```

### Example Queries

```sql
-- Show databases
SHOW DATABASES;

-- Show tables
USE appProdDB;
SHOW TABLES;

-- Check application data
SELECT COUNT(*) FROM users;
SELECT * FROM greetings LIMIT 10;
```

---

## Accessing Beanstalk Instances (Direct Shell)

Beanstalk instances are in private subnets, accessible only via bastion or ALN.

### Option A: Via Bastion Tunnel

```bash
# 1. SSH into bastion
aws ssm start-session --target ${BASTION_ID}

# 2. From bastion shell, SSH to Beanstalk instance
ssh -i /opt/bastion/.ssh/id_rsa ec2-user@10.66.10.15
```

### Option B: Direct SSM (if instance has IAM role)

```bash
# Get Beanstalk instance ID (replace with your ASG instance)
BEANSTALK_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "gc-api-prod-asg" \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

# Connect directly
aws ssm start-session --target ${BEANSTALK_ID}
```

---

## Application Logging & Monitoring

### View Beanstalk Logs

**Via AWS Console:**
1. Elastic Beanstalk → Environment → Logs
2. Request logs from last 100 lines or tail in real-time

**Via CLI:**
```bash
# Retrieve logs
aws elasticbeanstalk request-environment-info \
  --environment-name gc-api-prod \
  --info-type tail

# Fetch and stream
aws elasticbeanstalk retrieve-environment-info \
  --environment-name gc-api-prod \
  --info-type tail \
  --query 'EnvironmentInfo[0].Message' \
  --output text | tar xz -O | tail -f
```

### View ALB Access Logs

Logs are stored in S3.

```bash
# List ALB logs
aws s3 ls s3://gc-app-alb-logs-c8f7ewhysy5a/prod/AWSLogs/ --recursive

# Download and view
aws s3 cp s3://gc-app-alb-logs-c8f7ewhysy5a/prod/AWSLogs/123456789/elasticloadbalancing/us-west-1/2025-02-25/.../ . --recursive

# Parse ALB logs (find slow requests)
grep -i "elb_status_code.*5" *.log  # 5xx errors
awk '{print $NF}' *.log | sort -n | tail -20  # slowest requests
```

---

## Bastion Access Control (IAM)

### List Authorized Users

```bash
# All users in SSM access group
aws iam get-group --group-name prod-ssm-users \
  --query 'Users[*].[UserName,Arn]' \
  --output table
```

### Add User to SSM Group

```bash
# Add john.doe@company.com
aws iam add-user-to-group \
  --user-name john.doe \
  --group-name prod-ssm-users
```

### Remove User from SSM Group

```bash
# Remove john.doe@company.com
aws iam remove-user-from-group \
  --user-name john.doe \
  --group-name prod-ssm-users
```

---

## Restrict Access by IP (Optional)

Edit `05-ssm-access/prod.tfvars`:

```hcl
# Only allow these IPs to create SSM sessions
allowed_source_ips = [
  "70.181.86.188/32",      # Your office
  "203.0.113.45/32",        # Your home
  "203.0.113.0/24"          # Corporate VPN subnet
]
```

Then apply:

```bash
cd 05-ssm-access
terraform apply -var-file=prod.tfvars
cd ..
```

---

## Bastion Logs (SSM Sessions)

All SSM sessions are logged to CloudTrail and CloudWatch.

```bash
# View recent SSM session logs
aws logs tail /aws/ssm/session-logs --follow

# Find sessions for specific user
aws logs filter-log-events \
  --log-group-name /aws/ssm/session-logs \
  --filter-pattern '[username = "john.doe", ...]' \
  --query 'events[*].[timestamp,message]'
```

---

## VPN Access (Alternative to Bastion)

If your VPN is set up (see README.CERTIFICATES.md):

```bash
# Connect to VPN
openvpn --config bastion-client.ovpn

# Once connected, you get IP 172.20.1.x
# Can now access private resources directly:
curl http://10.66.10.15:8080/v1/greetings  # Beanstalk internal
mysql -h 10.66.20.10 -u appUser -p         # RDS internal
```

---

## Troubleshooting Access Issues

### SSM Session Won't Connect

```bash
# 1. Check instance status
aws ec2 describe-instances --instance-ids i-0123456789abcdef0 \
  --query 'Reservations[0].Instances[0].[State.Name,InstanceStatus.Status]'

# 2. Check IAM role has SSM permissions
aws iam get-role-policy \
  --role-name gc-api-prod-eb-ec2-role \
  --policy-name ssm-permissions

# 3. Check security group allows outbound to SSM (port 443)
aws ec2 describe-security-groups --group-ids sg-0123456789abcdef0

# 4. Verify instance has SSM agent running
aws ssm describe-instance-information

# 5. Check CloudTrail for errors
aws cloudtrail lookup-events --lookup-attributes AttributeKey=ResourceName,AttributeValue=gc-bastion-prod
```

### Can't Reach Database

```bash
# 1. Verify RDS endpoint is correct
aws rds describe-db-clusters --query 'DBClusters[0].[DBClusterIdentifier,Endpoint]'

# 2. Check security group allows 3306 from bastion
aws ec2 describe-security-groups --group-ids <RDS_SG_ID> | grep 3306

# 3. Verify database credentials
# (Ask your DBA or check Secrets Manager)
aws secretsmanager get-secret-value --secret-id prod/rds/app-user
```

### Port Forwarding Hangs

```bash
# 1. Check bastion health
aws ssm describe-instance-information --instance-information-filter-list key=tag:Name,valueSet=gc-bastion-prod

# 2. Restart the bastion and try again
# (Port forwarding usually recovers after 30 seconds)

# 3. Check CloudWatch logs for bastion
aws logs tail /aws/ssm/session-logs --follow

# 4. Try a simple SSM command first
aws ssm start-session --target <INSTANCE_ID> --document-name AWS-StartInteractiveCommand
```
