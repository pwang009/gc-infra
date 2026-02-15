# Stop and Start EC2 Instances Guide

This guide shows how to stop and start EC2 instances by scaling the Auto Scaling Group to save costs when not in use.

## Dev Environment - Stop and Start

**Stop (Scale to 0):**
```bash
asgName=dev-app-asg

# Update min_size to 0
aws autoscaling update-auto-scaling-group --auto-scaling-group-name ${asgName} --min-size 0

# Scale to 0 (terminates all instances)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name ${asgName} \
  --desired-capacity 0

# Verify instances are terminating
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name]' \
  --output table
```

**Start (Scale to 1):**
```bash
asgName=dev-app-asg

# Restore min_size to 1
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name ${asgName} \
  --min-size 1

# Scale to 1 instance
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name ${asgName} \
  --desired-capacity 1

# Wait for instance to launch (takes ~2-3 minutes)
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress]' \
  --output table
```

## Prod Environment - Stop and Start

**Stop (Scale to 0):**
```bash
asgName=prod-app-asg

# Update min_size to 0
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name ${asgName} \
  --min-size 0

# Scale to 0 (terminates all instances)
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name ${asgName} \
  --desired-capacity 0

# Verify instances are terminating
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=prod" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name]' \
  --output table
```

**Start (Scale to 2):**
```bash
asgName=prod-app-asg

# Restore min_size to 2
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name ${asgName} \
  --min-size 2

# Scale to 2 instances
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name ${asgName} \
  --desired-capacity 2

# Wait for instances to launch (takes ~2-3 minutes)
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=prod" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress]' \
  --output table
```

## Check ASG Status

**View current ASG configuration:**
```bash
# Dev
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names dev-app-asg \
  --query 'AutoScalingGroups[0].[AutoScalingGroupName,DesiredCapacity,MinSize,MaxSize]' \
  --output table

# Prod
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names prod-app-asg \
  --query 'AutoScalingGroups[0].[AutoScalingGroupName,DesiredCapacity,MinSize,MaxSize]' \
  --output table
```

**View instances in ASG:**
```bash
# Dev
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names dev-app-asg \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState,HealthStatus]' \
  --output table

# Prod
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names prod-app-asg \
  --query 'AutoScalingGroups[0].Instances[*].[InstanceId,LifecycleState,HealthStatus]' \
  --output table
```

## Important Notes

### What Happens When You Scale to 0
- All EC2 instances are **terminated** (not stopped)
- ASG, Launch Template, and other infrastructure remain intact
- No EC2 charges while scaled to 0
- When you scale back up, **new instances are launched** with fresh configuration

### What Persists
- ✅ Auto Scaling Group configuration
- ✅ Launch Template
- ✅ Security Groups
- ✅ IAM Roles
- ✅ VPC and networking
- ✅ JAR file in S3

### What is Lost
- ❌ Instance-specific data (logs, temporary files)
- ❌ Any manual changes made to the instance
- ❌ Instance IDs change (new instances get new IDs)

### Cost Savings
When scaled to 0, you only pay for:
- S3 storage (~$0.023/GB/month)
- NAT Gateway (~$0.045/hour = ~$32/month)
- VPC endpoints (free for S3 gateway endpoint)

**No charges for:**
- EC2 instances
- EBS volumes
- Data transfer (no instances running)

## Alternative: Use Terraform

You can also manage capacity via Terraform:

**Stop (scale to 0):**
```bash
# Edit dev.tfvars
# Change: desired_capacity = 0

cd 03-app-ec2-v1
terraform apply -var-file=dev.tfvars -auto-approve
```

**Start (scale back up):**
```bash
# Edit dev.tfvars
# Change: desired_capacity = 1

cd 03-app-ec2-v1
terraform apply -var-file=dev.tfvars -auto-approve
```

## Troubleshooting

### ASG not scaling down
**Check if there are any scaling policies preventing scale-down:**
```bash
aws autoscaling describe-policies \
  --auto-scaling-group-name dev-app-asg
```

### Instances not launching
**Check ASG activity:**
```bash
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name dev-app-asg \
  --max-records 5
```

### Need to force terminate instances
```bash
# Get instance IDs
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names dev-app-asg \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
  --output text

# Terminate specific instance
aws ec2 terminate-instances --instance-ids i-xxxxxxxxxxxxxxxxx
```
