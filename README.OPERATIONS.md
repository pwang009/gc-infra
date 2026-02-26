# GC API Production Stack - Operations & Monitoring

## Overview

Day-to-day operations, monitoring, troubleshooting, and performance optimization for the production stack.

---

## X-Ray Distributed Tracing

### View Service Map

1. **AWS Console**:
   - X-Ray → Service Map
   - See ALB → Beanstalk → RDS flow
   - Click nodes to drill down

2. **CLI**:
```bash
# Get service graph
aws xray get-service-graph --start-time $(date -u -Iseconds -d '1 hour ago') --end-time $(date -u -Iseconds)

# Get traces for a specific service
aws xray get-trace-summaries --start-time $(date -u -Iseconds -d '1 hour ago') --end-time $(date -u -Iseconds) --filter-expression "service(\"gc-api\")"
```

### Analyze Performance

```bash
# Get slowest requests
aws xray batch-get-traces --trace-ids $(aws xray get-trace-summaries \
  --start-time $(date -u -Iseconds -d '1 hour ago') \
  --end-time $(date -u -Iseconds) \
  --query 'TraceSummaries[*].Id' \
  --output text) | jq '.Traces[] | {Id, Duration}'
```

### Check Sampling Rules

```bash
# List active sampling rules
aws xray list-sampling-rules

# Check sampling rule details
aws xray get-sampling-rule-updates
```

---

## CloudWatch Monitoring

### Beanstalk Application Metrics

```bash
# CPU utilization
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElasticBeanstalk \
  --metric-name TargetResponseTime \
  --dimensions Name=EnvironmentName,Value=gc-api-prod \
  --start-time $(date -u -Iseconds -d '1 hour ago') \
  --end-time $(date -u -Iseconds) \
  --period 300 \
  --statistics Average,Maximum
```

### RDS Metrics

```bash
# Database CPU
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBClusterIdentifier,Value=prod-aurora-cluster \
  --start-time $(date -u -Iseconds -d '1 hour ago') \
  --end-time $(date -u -Iseconds) \
  --period 300 \
  --statistics Average,Maximum

# Database connections
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name DatabaseConnections \
  --dimensions Name=DBClusterIdentifier,Value=prod-aurora-cluster \
  --start-time $(date -u -Iseconds -d '1 hour ago') \
  --end-time $(date -u -Iseconds) \
  --period 300 \
  --statistics Average,Sum
```

### ALB Metrics

```bash
# Request count
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name RequestCount \
  --dimensions Name=LoadBalancer,Value=app/gc-prod-app-alb/1234567890abcdef \
  --start-time $(date -u -Iseconds -d '1 hour ago') \
  --end-time $(date -u -Iseconds) \
  --period 300 \
  --statistics Sum

# Target response time
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name TargetResponseTime \
  --dimensions Name=LoadBalancer,Value=app/gc-prod-app-alb/1234567890abcdef \
  --start-time $(date -u -Iseconds -d '1 hour ago') \
  --end-time $(date -u -Iseconds) \
  --period 300 \
  --statistics Average,Maximum

# 5xx errors
aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --dimensions Name=LoadBalancer,Value=app/gc-prod-app-alb/1234567890abcdef \
  --start-time $(date -u -Iseconds -d '1 hour ago') \
  --end-time $(date -u -Iseconds) \
  --period 300 \
  --statistics Sum
```

### Create Dashboards

**Via Console:**
CloudWatch → Dashboards → Create Dashboard → Add widgets

**Via CLI:**
```bash
aws cloudwatch put-dashboard \
  --dashboard-name gc-api-prod \
  --dashboard-body file://dashboard.json
```

---

## Logs Analysis

### ALB Access Logs

```bash
# Find 5xx errors
aws s3 cp s3://gc-alb-logs-bucket/prod/ . --recursive
grep ' 5[0-9][0-9] ' *.log | wc -l

# Find slow requests (>1s response time)
awk '$NF > 1000 {print}' *.log | head -20

# Count by HTTP method
cut -d' ' -f6 *.log | sort | uniq -c | sort -rn

# Count by URL path
cut -d' ' -f12 *.log | sort | uniq -c | sort -rn
```

### CloudWatch Logs

```bash
# Tail Beanstalk logs
aws logs tail /aws/elasticbeanstalk/gc-api-prod/var/log/eb-engine.log --follow

# Tail X-Ray insights
aws logs tail /aws/x-ray/prod/insights --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/elasticbeanstalk/gc-api-prod/var/log/eb-engine.log \
  --filter-pattern "ERROR" \
  --query 'events[*].[timestamp,message]'

# Get log group statistics
aws logs describe-log-groups --log-group-name-prefix /aws/elasticbeanstalk
```

### Application Logs (from Bastion)

```bash
# Connect to Beanstalk instance via bastion
aws ssm start-session --target <BEANSTALK_ID>

# View application logs
sudo tail -f /var/log/eb-activity.log
sudo tail -f /opt/elasticbeanstalk/tasks/bundlelogs/eb-maven-2.log

# Check application status
curl http://localhost:8080/actuator/health
curl http://localhost:8080/actuator/metrics
```

---

## Scaling & Performance

### ASG Scaling  Policies

```bash
# Current ASG state
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names gc-api-prod-asg \
  --query 'AutoScalingGroups[0].[DesiredCapacity,MinSize,MaxSize]'

# Set target capacity
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name gc-api-prod-asg \
  --desired-capacity 4

# List scaling activities
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name gc-api-prod-asg \
  --max-records 10
```

### RDS Scaling

```bash
# Current instance class
aws rds describe-db-instances \
  --db-instance-identifier prod-aurora-primary \
  --query 'DBInstances[0].[DBInstanceClass,AllocatedStorage]'

# Modify instance (requires maintenance window)
aws rds modify-db-instance \
  --db-instance-identifier prod-aurora-primary \
  --db-instance-class db.t3.medium \
  --apply-immediately  # or wait for maintenance window
```

### Load Testing

```bash
# Install Apache Bench
sudo yum install httpd-tools

# Run load test
ab -n 10000 -c 100 https://api.abc.com/v1/greetings

# Monitor with X-Ray during load test
# Check service map for bottlenecks
```

---

## Alerts & Auto-Recovery

### Create Alarms

```bash
# Alert on 5xx errors
aws cloudwatch put-metric-alarm \
  --alarm-name gc-api-5xx-errors \
  --alarm-description "Alert when 5xx errors exceed 10 in 5 minutes" \
  --metric-name HTTPCode_Target_5XX_Count \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --period 300 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 1 \
  --alarm-actions arn:aws:sns:us-west-1:123456789:prod-alerts

# Alert on RDS high CPU
aws cloudwatch put-metric-alarm \
  --alarm-name gc-rds-high-cpu \
  --alarm-description "Alert when RDS CPU > 80%" \
  --metric-name CPUUtilization \
  --namespace AWS/RDS \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=DBClusterIdentifier,Value=prod-aurora-cluster \
  --alarm-actions arn:aws:sns:us-west-1:123456789:prod-alerts
```

### Set Up SNS Notifications

```bash
# Create SNS topic
aws sns create-topic --name prod-alerts

# Subscribe email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-west-1:123456789:prod-alerts \
  --protocol email \
  --notification-endpoint ops@company.com
```

---

## Security & Audits

### Review CloudTrail Logs

```bash
# Recent API calls
aws cloudtrail lookup-events \
  --max-results 50 \
  --start-time $(date -u -Iseconds -d '24 hours ago')

# Filter by resource  
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=gc-api-prod

# Find failed operations
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=CreateDatabase \
  --max-results 50 | jq '.Events[] | {EventTime, EventName, Username}'
```

### Audit IAM Access

```bash
# Users with SSM access
aws iam get-group --group-name prod-ssm-users \
  --query 'Users[*].UserName'

# Users who accessed Beanstalk recently
aws iam list-access-keys --user-name <username> | jq '.AccessKeyMetadata'
```

### Verify Encryption

```bash
# Check RDS encryption
aws rds describe-db-instances \
  --db-instance-identifier prod-aurora-primary \
  --query 'DBInstances[0].[StorageEncrypted,KmsKeyId]'

# Check EBS encryption
aws ec2 describe-volumes \
  --filters "Name=encrypted,Values=false" \
  --query 'Volumes[*].[VolumeId,Size]'
```

---

## Disaster Recovery

### Backup Strategy

**RDS Automated Backups:**
```bash
# Check backup retention
aws rds describe-db-instances \
  --db-instance-identifier prod-aurora-primary \
  --query 'DBInstances[0].[BackupRetentionPeriod,PreferredBackupWindow]'

# Manual snapshot
aws rds create-db-cluster-snapshot \
  --db-cluster-snapshot-identifier prod-aurora-backup-$(date +%Y%m%d) \
  --db-cluster-identifier prod-aurora-cluster
```

**Beanstalk Deployments:**
```bash
# List application versions
aws elasticbeanstalk describe-application-versions \
  --application-name gc-api \
  --query 'ApplicationVersions[*].[VersionLabel,DateCreated]'

# Rollback to previous version
aws elasticbeanstalk update-environment \
  --application-name gc-api \
  --environment-name gc-api-prod \
  --version-label v1.5  # previous stable version
```

### Restore from Snapshot

```bash
# Restore RDS from snapshot
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier prod-aurora-restored \
  --snapshot-identifier prod-aurora-backup-20250225 \
  --engine aurora-mysql

# Restore Beanstalk from S3
aws elasticbeanstalk create-environment \
  --application-name gc-api \
  --environment-name gc-api-prod-restore \
  --version-label v1.5 \
  --solution-stack-name "64bit Amazon Linux 2023 v6.0.0 running Java 21"
```

---

## Cost Optimization

### Review Spending

```bash
# Cost by service
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '30 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "BlendedCost" \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[0].Groups'

# Cost by environment
aws ce get-cost-and-usage \
  --time-period Start=$(date -u -d '30 days ago' +%Y-%m-%d),End=$(date -u +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics "BlendedCost" \
  --filter '{ComparisonOperator: CONTAINS, Key: "TAG:Environment", Values: ["prod"]}'
```

### Optimization Tips

- **Destroy dev when idle**: Save ~$150/month
- **Use Reserved Instances**: 20-30% savings in prod
- **Reduce X-Ray sampling**: From 50% to 10% in dev
- **Right-size instances**: Monitor CloudWatch metrics
- **Delete old snapshots**: 30-day retention is typical
- **Consolidate ALBs**: One ALB for multiple apps if possible

---

## Troubleshooting

### Beanstalk Instances Unhealthy

```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:...

# SSH to instance and check logs
aws ssm start-session --target <INSTANCE_ID>
sudo tail -f /var/log/eb-engine.log

# Check application running
curl http://localhost:8080/v1/greetings
```

### RDS Connection Issues

```bash
# Test connectivity from bastion
aws ssm start-session --target <BASTION_ID>
telnet prod-aurora-cluster.cluster-cdqmgwiqilow.us-west-1.rds.amazonaws.com 3306

# Check security group
aws ec2 describe-security-groups --group-ids <RDS_SG_ID>

# Check RDS parameter groups
aws rds describe-db-cluster-parameters \
  --db-cluster-parameter-group-name prod-aurora-params
```

### High Latency or Errors

1. **Check X-Ray service map** for bottlenecks
2. **Review CloudWatch metrics**: CPU, memory, connections
3. **Analyze ALB logs** for 5xx errors
4. **Scale up ASG** if Beanstalk is overloaded
5. **Upgrade RDS instance** if database is slow
6. **Check database slow log**:
   ```bash
   aws rds describe-db-log-files \
     --db-instance-identifier prod-aurora-primary \
     --log-type error
   ```

### VPN Connection Issues

```bash
# Bastion OpenVPN status
aws ssm start-session --target <BASTION_ID>
sudo systemctl status openvpn-server@server
sudo journalctl -u openvpn-server@server -f

# Check client logs
tail -f /var/log/openvpn/openvpn.log

# Test connectivity
ping 172.20.1.1  # VPN gateway
nslookup api.abc.com
curl https://api.abc.com/v1/greetings
```

---

## Maintenance & Updates

### Apply Security Patches

```bash
# Update Beanstalk platform
aws elasticbeanstalk list-platform-versions \
  --filters Operator=equals,OperatorValue=supported

# Update environment to new platform
aws elasticbeanstalk update-environment \
  --application-name gc-api \
  --environment-name gc-api-prod \
  --platform-arn arn:aws:elasticbeanstalk:us-west-1::platform/...
```

### Update Dependencies

1. **Java/Spring Boot**: Update `pom.xml`, rebuild JAR, deploy new version
2. **Terraform**: `terraform init -upgrade` after updating provider versions
3. **RDS**: Minor version updates are automatic; major requires planning
4. **OpenVPN**: `sudo yum update openvpn`

---

## Runbooks

### Emergency: High Traffic Spike

1. Scale Beanstalk ASG to max: `aws autoscaling set-desired-capacity ... --desired-capacity 6`
2. Enable ALB throttling: Reduce max connections per IP
3. Monitor X-Ray for slow db queries
4. Scale RDS if CPU >80%: `aws rds modify-db-instance ... --db-instance-class db.t3.medium`
5. Contact vendor if issue persists

### Emergency: Database Down

1. Check RDS cluster status: `aws rds describe-db-clusters`
2. Promote read replica if available: `aws rds promote-replicas`
3. Restore from latest snapshot: `aws rds restore-db-cluster-from-snapshot ...`
4. Update Beanstalk environment variable with new RDS endpoint
5. Redeploy application

### Emergency: API Not Responding

1. Check ALB health: `aws elbv2 describe-target-health ...`
2. Check Beanstalk environment status: `aws elasticbeanstalk describe-environments`
3. SSH via bastion and check application status: `curl localhost:8080/actuator/health`
4. Check cloudwatch logs: `aws logs tail /aws/elasticbeanstalk/...`
5. Rollback to previous deploy: `aws elasticbeanstalk list-event-descriptions`
