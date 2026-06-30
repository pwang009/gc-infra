# GC Infrastructure Access Guide

This guide documents the supported ways to access the private infrastructure in this stack. The recommended path is:

1. Use AWS Systems Manager Session Manager for shell access.
2. Use SSM port forwarding for database access.
3. Use the application endpoint or load balancer for normal application traffic.

## Prerequisites

Before you start, make sure you have:

- AWS CLI v2 installed and configured
- The Session Manager plugin installed
- Access to the appropriate IAM permissions for SSM, EC2, and RDS
- Optional: a PostgreSQL client such as psql for direct database queries

### Install the Session Manager plugin

WSL Ubuntu / Ubuntu Linux:
```bash
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o session-manager-plugin.deb
sudo apt update
sudo dpkg -i session-manager-plugin.deb
sudo apt-get install -f -y
```

If you are using WSL and the plugin is not recognized, restart WSL after installation:
```bash
wsl --shutdown
```

Verify the installation:
```bash
session-manager-plugin
```

macOS:
```bash
brew install --cask session-manager-plugin
```

Windows:
Download the installer from the AWS Session Manager plugin page.

---

## 1. Connect to the bastion with Session Manager

Set your environment first:

```bash
# export ENV=prod   # or dev
export ENV=dev   
```

Find the bastion instance ID:

```bash
BASTION_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=gc-bastion-${ENV}" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)
echo $BASTION_ID
```

Start an interactive shell:

```bash
aws ssm start-session --target "$BASTION_ID"
```

Once connected, you can check the host and inspect the stack:

```bash
uptime
df -h
sudo systemctl status xray 2>/dev/null || true
```

---

## 2. Access RDS through a local port forward

The most secure way to reach the database is to open a tunnel from your machine through the bastion.

### Start the port forward

```bash
export ENV=dev
export BASTION_ID=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=gc-bastion-${ENV}" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --output text)

export RDS_ENDPOINT=$(aws rds describe-db-clusters \
  --query 'DBClusters[0].Endpoint' \
  --output text)

echo "$RDS_ENDPOINT"

aws ssm start-session --target "$BASTION_ID" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters "{
    \"host\":[\"$RDS_ENDPOINT\"],
    \"portNumber\":[\"5432\"],
    \"localPortNumber\":[\"5432\"]
  }"
```

Leave that terminal open, then verify the local tunnel is listening in a second terminal:

```bash
nc -vz 127.0.0.1 5432
```

You should see a success message such as `Connection to 127.0.0.1 5432 port [tcp/postgresql] succeeded!` before connecting locally:

```bash
psql "host=127.0.0.1 port=5432 dbname=goodconnex user=<db_user>"
```

You will be prompted for the database password. If you need the credentials, retrieve them from the appropriate secret store or ask the platform owner.

### Example queries

```sql
\l
\c <database_name>
\dt
```

---

## 3. Reach private application instances

Private application hosts are not directly reachable from the public internet. Use one of the following patterns.

### Option A: Use the bastion as a jump host

From your local machine, start a Session Manager session to the bastion, then from the bastion shell connect to the target instance:

```bash
ssh -i /opt/bastion/.ssh/id_rsa ec2-user@<private-ip>
```

### Option B: Connect directly with SSM

If the target instance is configured with an SSM-enabled IAM role, you can connect directly:

```bash
INSTANCE_ID=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names "<asg-name>" \
  --query 'AutoScalingGroups[0].Instances[0].InstanceId' \
  --output text)

aws ssm start-session --target "$INSTANCE_ID"
```

> Prefer the bastion when you are troubleshooting shared infrastructure, especially when multiple teams may be involved.

---

## 4. Review logs and monitoring data

### Application logs

Use the Elastic Beanstalk console or CLI to fetch logs:

```bash
aws elasticbeanstalk request-environment-info \
  --environment-name <environment-name> \
  --info-type tail

aws elasticbeanstalk retrieve-environment-info \
  --environment-name <environment-name> \
  --info-type tail \
  --query 'EnvironmentInfo[0].Message' \
  --output text | tar xz -O | tail -f
```

### ALB access logs

ALB logs are stored in S3. You can list and download them with the AWS CLI:

```bash
aws s3 ls s3://<alb-log-bucket>/<env>/AWSLogs/ --recursive
```

---

## 5. Manage who can use the bastion

List the users currently allowed to use the SSM access group:

```bash
aws iam get-group --group-name prod-ssm-users \
  --query 'Users[*].[UserName,Arn]' \
  --output table
```

Add or remove a user:

```bash
aws iam add-user-to-group \
  --user-name <username> \
  --group-name prod-ssm-users
```

```bash
aws iam remove-user-from-group \
  --user-name <username> \
  --group-name prod-ssm-users
```

If you want to restrict access by source IP, update the SSM access module inputs and apply the change from the relevant Terraform folder.

---

## 6. Session logging and auditability

SSM sessions are recorded to CloudTrail and CloudWatch Logs. Review them when you need to verify who accessed the bastion and when.

```bash
aws logs tail /aws/ssm/session-logs --follow
```

To search for sessions by user:

```bash
aws logs filter-log-events \
  --log-group-name /aws/ssm/session-logs \
  --filter-pattern '[username = "<username>", ...]' \
  --query 'events[*].[timestamp,message]'
```

---

## 7. Troubleshooting

### SSM session will not start

Check the instance state, SSM agent health, and IAM permissions:

```bash
aws ec2 describe-instances --instance-ids <instance-id> \
  --query 'Reservations[0].Instances[0].[State.Name,InstanceStatus.Status]'

aws ssm describe-instance-information
```

If SSM still fails, confirm that the instance role includes the required SSM policy and that outbound HTTPS access is allowed.

### Cannot reach the database

Verify the endpoint, inbound security group rules, and secrets:

```bash
aws rds describe-db-clusters --query 'DBClusters[0].[DBClusterIdentifier,Endpoint]'
aws secretsmanager get-secret-value --secret-id <secret-id>
```

### Port forwarding appears stuck

Check the bastion health and retry the session:

```bash
aws ssm describe-instance-information --instance-information-filter-list key=tag:Name,valueSet=gc-bastion-prod
```

If the tunnel is still unstable, restart the bastion and try again.

---

## Security notes

- Use SSM rather than opening direct SSH access to private instances whenever possible.
- Keep IAM permissions scoped to the minimum required for the task.
- Treat bastion access as privileged access and review session logs regularly.
- If VPN access is part of your environment, use it only when the network path requires it.
