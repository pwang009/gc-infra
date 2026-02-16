# Deployment Guide

## Quick Start

### Deploy Infrastructure

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

### Destroy Infrastructure

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
