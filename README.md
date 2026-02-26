# GC API Production Stack

Complete infrastructure-as-code for a 3-tier REST API running on AWS with Elastic Beanstalk, RDS, ALB, VPN Gateway, and distributed tracing.

## Quick Links

- **[Architecture Overview](README.ARCHITECTURE.md)** — System design, components, and data flow
- **[Deployment Guide](README.DEPLOYMENT.md)** — Step-by-step infrastructure setup
- **[Certificate & VPN Setup](README.CERTIFICATES.md)** — ACM certs, VPN configuration, DNS
- **[Access & Connectivity](README.ACCESS.md)** — Bastion, SSM, port forwarding, database access
- **[Operations](README.OPERATIONS.md)** — Monitoring, X-Ray, logs, scaling, troubleshooting

---

## Stack Overview

```
┌─────────────────────────────────────────────────────┐
│         Clients / External Users                    │
└──────────────────────┬────────────────────────────┘
                       │
        ┌──────────────┴──────────────┐
        │                             │
    api.abc.com                  vpn.abc.com
        │                             │
    ┌───▼───┐                     ┌───▼────┐
    │  ALB  │                     │  NLB   │
    │(HTTPS)│                     │(TLS/UDP)
    └───┬───┘                     └───┬────┘
        │                             │
    ┌───▼─────────────────────────────▼───┐
    │         VPC 10.66.0.0/16             │
    │                                      │
    │  ┌──────────────────────────────┐   │
    │  │ Elastic Beanstalk (v1 + v2)  │   │
    │  │ - Spring Boot API            │   │
    │  │ - Auto-scaling group         │   │
    │  └────────────┬─────────────────┘   │
    │               │                      │
    │  ┌────────────▼──────────────────┐   │
    │  │ RDS Aurora MySQL (Multi-AZ)   │   │
    │  │ Private subnet, pooled access │   │
    │  └───────────────────────────────┘   │
    │                                      │
    │  ┌───────────────────────────────┐   │
    │  │ Bastion (VPN + SSM Gateway)   │   │
    │  │ - OpenVPN server (1194/UDP)   │   │
    │  │ - TLS endpoints (443/943)     │   │
    │  │ - X-Ray daemon                │   │
    │  └───────────────────────────────┘   │
    └──────────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
    ┌───▼────┐             ┌─────▼─────┐
    │CloudWatch│             │X-Ray Tracing│
    │ Logs/Metrics│         │ Service Map│
    └──────────┘             └────────────┘
```

---

## Key Features

✅ **High Availability**
- Multi-AZ RDS Aurora
- ASG with min/max scaling
- ALB across 2+ AZs

✅ **Security**
- Private subnets for application & database
- Network segmentation (public/private/DB subnets)
- ACM certificates with auto-renewal
- SSM-only bastion access (no SSH keys)
- VPN for remote access with encryption

✅ **Scalability**
- Elastic Beanstalk auto-scaling (2-6 instances)
- RDS Aurora serverless option available
- ALB path-based routing (v1 and v2 APIs)

✅ **Observability**
- AWS X-Ray distributed tracing
- CloudWatch logs aggregation
- ALB access logs to S3
- Performance insights

✅ **Cost Optimization**
- t3 burstable instances (dev: t3.micro, prod: t3.small)
- Pay-as-you-go RDS Aurora
- X-Ray sampling (10% prod, 50% dev)
- Destroy dev when idle

---

## Architecture Components

| Component | Purpose | Subnet Type |
|-----------|---------|------------|
| 01-network | VPC, subnets, NAT | N/A |
| 02-db | RDS Aurora cluster | Private-DB |
| 03-bastion | Bastion EC2 + NLB (VPN) | Public |
| 03-ebs-v1 | Spring Boot v1 API | Private |
| 03-ebs-v2 | Spring Boot v2 API | Private |
| 04-alb | Application Load Balancer | Public |
| 05-ssm-access | IAM policies for SSM | N/A |
| 06-x-ray | X-Ray sampling & tracing | N/A |

---

## Prerequisites

- AWS Account with permissions to create EC2, RDS, ALB, VPC
- AWS CLI v2 installed and configured
- Terraform v1.5+
- Registered domain with GoDaddy (for DNS records)
- Optional: OpenVPN client (for VPN access)

**Install AWS Session Manager Plugin:**
```bash
# macOS
brew install --cask session-manager-plugin

# Linux
curl "https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb" -o "session-manager-plugin.deb"
sudo dpkg -i session-manager-plugin.deb
```

---

## Getting Started

### 1. Clone & Setup

```bash
git clone <repo>
cd terraform

# Set environment
export ENV=prod  # or dev
```

### 2. Request ACM Certificates

Before deploying infrastructure:

```bash
# For ALB (api.abc.com)
aws acm request-certificate --domain-name api.abc.com --validation-method DNS --region us-west-1

# For VPN (vpn.abc.com)
aws acm request-certificate --domain-name vpn.abc.com --validation-method DNS --region us-west-1

# Wait for validation → Complete in GoDaddy DNS
# See README.CERTIFICATES.md for detailed steps
```

### 3. Deploy Infrastructure

Follow **[README.DEPLOYMENT.md](README.DEPLOYMENT.md)** for step-by-step instructions in order:

1. Network (01-network)
2. Database (02-db)
3. Bastion (03-bastion)
4. Beanstalk v1 (03-ebs-v1)
5. Beanstalk v2 (03-ebs-v2)
6. Load Balancer (04-alb)
7. SSM Access (05-ssm-access)
8. X-Ray (06-x-ray)

### 4. Access Resources

See **[README.ACCESS.md](README.ACCESS.md)** for:
- Connecting to bastion via SSM
- Port forwarding to RDS
- Viewing logs and monitoring

### 5. Monitor & Optimize

See **[README.OPERATIONS.md](README.OPERATIONS.md)** for:
- X-Ray service map
- CloudWatch dashboards
- Scaling policies
- Cost optimization

---

## Directory Structure

```
.
├── 01-network/          # VPC, subnets, NAT, security groups
├── 02-db/               # RDS Aurora cluster, proxy
├── 03-ebs-v1/           # Beanstalk v1 app + ALB config
├── 03-ebs-v2/           # Beanstalk v2 app
├── 03-bastion/          # Bastion EC2, NLB (VPN), OpenVPN
├── 04-alb/              # ALB with path-based routing
├── 05-ssm-access/       # IAM policies for SSM access
├── 06-x-ray/            # X-Ray configuration & sampling
├── README.md            # This file
├── README.ARCHITECTURE.md
├── README.DEPLOYMENT.md
├── README.CERTIFICATES.md
├── README.ACCESS.md
└── README.OPERATIONS.md
```

---

## Variables & Customization

Each module has `prod.tfvars` and `dev.tfvars` to customize:

```hcl
# Example: 01-network/prod.tfvars
environment        = "prod"
vpc_cidr           = "10.66.0.0/16"
public_subnets     = ["10.66.1.0/24", "10.66.2.0/24"]
private_subnets    = ["10.66.10.0/24", "10.66.11.0/24"]
```

---

## Cost Estimates

| Environment | Monthly Cost |
|-------------|--------------|
| **Dev** | ~$180 |
| **Prod** | ~$200 |

**Tip:** Destroy dev when not in use to save ~$150/month

---

## Troubleshooting

### Common Issues

**Terraform state not found:**
```bash
aws s3 ls s3://gc-terraform-state-c8f7ewhysy5a
```

**Bastion can't reach RDS:**
Check security group rules allow port 3306 from bastion to RDS.

**API not responding via ALB:**
Check health checks in target groups (Status → Healthy/Unhealthy).

**X-Ray traces not showing:**
Verify IAM role has `xray:PutTraceSegments` permission.

For more details, see **[README.OPERATIONS.md](README.OPERATIONS.md#troubleshooting)**.

---

## Support & Documentation

- [AWS Elastic Beanstalk Docs](https://docs.aws.amazon.com/elastic-beanstalk/)
- [AWS RDS Aurora Docs](https://docs.aws.amazon.com/rds/)
- [AWS X-Ray Docs](https://docs.aws.amazon.com/xray/)
- [OpenVPN Access Server Docs](https://openvpn.net/access-server-docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest)

---

## License

Internal use only. Do not distribute.
