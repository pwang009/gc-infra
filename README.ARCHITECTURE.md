# GC API Production Stack - Architecture

## System Overview

```
┌──────────────────────────────────────────────────────────────┐
│                      Internet / Users                         │
└──────────────────────────────┬───────────────────────────────┘
                               │
              ┌────────────────┴────────────────┐
              │                                 │
      api.goodconnex.com                vpn.goodconnex.com
              │                                 │
    ┌─────────▼─────────┐           ┌──────────▼──────────┐
    │  ALB (Public)     │           │  NLB (Public)       │
    │ 10.66.1/2.0/24    │           │ 10.66.1/2.0/24      │
    │ 80/443            │           │ 1194/443/943 TLS    │
    └─────────┬─────────┘           └──────────┬──────────┘
              │                                │
    ┌─────────▼──────────────────────────────┬────────────┐
    │      VPC 10.66.0.0/16                  │            │
    │                                        │            │
    │ ┌──────────────────────────────────┐   │            │
    │ │ Public Subnets: 10.66.1.0/24     │   │            │
    │ │                10.66.2.0/24      │   │            │
    │ │                                  │   │            │
    │ │ (ALB, NLB, NAT Gateway)          │   │            │
    │ └──────────────────────────────────┘   │            │
    │                                        │            │
    │ ┌──────────────────────────────────┐   │            │
    │ │ Private Subnets: 10.66.10.0/24   │   │            │
    │ │                 10.66.11.0/24    │   │            │
    │ │                                  │   │            │
    │ │  ┌──────────────────────────┐    │   │            │
    │ │  │ Elastic Beanstalk (v1/v2)│    │   │            │
    │ │  │ - Spring Boot API        │    │   │            │
    │ │  │ - Java 21                │    │   │            │
    │ │  │ - ASG: 2/6               │    │   │            │
    │ │  │ - t3.small (prod)        │    │   │            │
    │ │  └────────────┬─────────────┘    │   │            │
    │ │               │                  │   │            │
    │ │  ┌────────────▼──────────────┐   │   │            │
    │ │  │ Bastion (VPN/SSM)         │   │   │            │
    │ │  │ - Private: 10.66.10/11    │   │   │            │
    │ │  │ - OpenVPN 1194/UDP        │   │   │            │
    │ │  │ - Admin 943/443 TCP       │   │   │            │
    │ │  │ - X-Ray daemon            │   │   │            │
    │ │  └───────────────────────────┘   │   │            │
    │ └──────────────────────────────────┘   │            │
    │                                        │            │
    │ ┌──────────────────────────────────┐   │            │
    │ │ DB Subnets: 10.66.20.0/24        │   │            │
    │ │             10.66.21.0/24        │   │            │
    │ │                                  │   │            │
    │ │  ┌──────────────────────────┐    │   │            │
    │ │  │ RDS Aurora MySQL         │    │   │            │
    │ │  │ - Multi-AZ               │    │   │            │
    │ │  │ - t3.small/medium        │    │   │            │
    │ │  └──────────────────────────┘    │   │            │
    │ └──────────────────────────────────┘   │            │
    │                                        │            │
    └────────────────────────────────────────┴────────────┘
                                             │
                           ┌─────────────────▼──────────┐
                           │ CloudWatch / X-Ray / Logs  │
                           │ - Centralized Monitoring   │
                           │ - Distributed Tracing      │
                           │ - Performance Insights     │
                           └────────────────────────────┘
```

## Component Details

### 1. Network Layer (01-network)
- **VPC**: 10.66.0.0/16
- **Public Subnets**: 10.66.1.0/24, 10.66.2.0/24 (ALB, NLB, NAT Gateway)
- **Private Subnets**: 10.66.10.0/24, 10.66.11.0/24 (Beanstalk, Bastion)
- **Database Subnets**: 10.66.20.0/24, 10.66.21.0/24 (RDS Aurora)
- **NAT Gateway**: Allows private instances to reach the internet (in public subnet)

### 2. Database Layer (02-db)
- **RDS Aurora MySQL** (Multi-AZ)
- **Cluster Endpoint** for write operations
- **Reader Endpoint** for read-only queries
- **RDS Proxy** for connection pooling (optional)
- **Private subnets** 10.66.20.0/24, 10.66.21.0/24

### 3. Application Layer (03-ebs-v1 / 03-ebs-v2)
- **Elastic Beanstalk** (managed EC2 + ASG)
- **Spring Boot API** (Java 21)
- **Versions**: v1 (/v1/*), v2 (/v2/*) routes
- **Instance Size**: t3.small (prod), t3.micro (dev)
- **ASG**: Min 2, Max 6, Desired 2
- **Private subnet** placement (no public IP)
- **Access**: Only via ALB or SSM/Bastion

### 4. Load Balancer (04-alb)
- **Application Load Balancer** (Layer 7)
- **Port 80**: HTTP (redirects to 443)
- **Port 443**: HTTPS (ACM certificate)
- **Path-based routing**:
  - `/v1/*` → v1 Beanstalk target group
  - `/v2/*` → v2 Beanstalk target group
- **Health checks**: `/v1/greetings`, `/v2/greetings`
- **Access logs**: S3 bucket for audit trail

### 5. VPN Gateway (03-bastion)
- **Network Load Balancer** (Layer 4, ultra-high performance)
  - Located in **public subnets** (10.66.1.0/24, 10.66.2.0/24)
  - Accepts incoming VPN traffic from the internet
- **Bastion EC2** (t3.micro)
  - Located in **private subnet** (10.66.10.0/24 or 10.66.11.0/24)
  - Runs OpenVPN server daemon
  - Accessible only via NLB or SSM Session Manager
- **OpenVPN Server**:
  - Port 1194/UDP: VPN tunnel (encrypted)
  - Port 943/TCP: Admin portal (HTTPS via NLB)
  - Port 443/TCP: Client profile download (HTTPS via NLB)
- **VPN Client Subnet**: 172.20.1.0/24 (clients get IPs from this range)
- **ACM Certificate** for TLS termination on NLB ports 943/443

### 6. SSM Access (05-ssm-access)
- **AWS Systems Manager** Session Manager
- **IAM roles** for bastion EC2
- **SSH alternative** (no key pairs needed, AWS-managed)
- **Port forwarding** to RDS database
- **CloudTrail logging** for audit

### 7. Monitoring & Tracing (06-x-ray)
- **AWS X-Ray**: Distributed tracing
  - Traces ALB → Beanstalk → RDS flow
  - Service map visualization
  - Performance insights
- **CloudWatch Logs**: Application logs, ALB logs
- **CloudWatch Metrics**: CPU, memory, latency
- **Sampling**: 10% prod, 50% dev to optimize costs

## Traffic Flow Example

### Typical API Request (api.abc.com/v1/greetings)
```
1. Client → ALB (HTTPS, public IP)
   → ALB resolves path to /v1/* → v1 target group
   
2. ALB → Beanstalk EC2 (private, port 8080/HTTP)
   → Spring Boot receives request
   
3. Beanstalk → RDS Aurora (private, port 3306)
   → Database query/write
   
4. Response → ALB → Client
```

### VPN Client Access (vpn.abc.com:1194)
```
1. Client → NLB (UDP 1194, public IP)
   → OpenVPN tunnel established
   
2. Client gets IP 172.20.1.x from server
   → Can now access 10.66.0.0/16 (VPC)
   
3. Client curl http://api.abc.com/v1/greetings
   → Routed through VPN tunnel (encrypted)
   → ALB processes normally
```

### SSM Session Manager (Bastion Access)
```
1. Local terminal → AWS Systems Manager
   → EC2 instance in private subnet
   
2. No SSH key needed (IAM-based auth)
   → Session logs to CloudTrail
   
3. Port forwarding for RDS:
   localhost:3306 → RDS 10.66.20.x:3306
```

## Deployment Modules & Order

| Order | Module | Purpose | Dependencies |
|-------|--------|---------|--------------|
| 1 | 01-network | VPC, subnets, NAT, security groups | None |
| 2 | 02-db | RDS Aurora cluster | 01-network |
| 3 | 03-bastion | Bastion EC2, NLB, VPN | 01-network |
| 4 | 03-ebs-v1 | Beanstalk v1 app | 01-network, 02-db |
| 5 | 03-ebs-v2 | Beanstalk v2 app | 01-network, 02-db |
| 6 | 04-alb | ALB with path routing | 01-network, 03-ebs-v1, 03-ebs-v2 |
| 7 | 05-ssm-access | IAM + SSM bastion access | 01-network, 03-bastion |
| 8 | 06-x-ray | X-Ray sampling & tracing | None (but attach to 03-ebs-v1/v2) |

## Security Posture

- **Network Segmentation**: Public (ALB/NLB/NAT) → Private (Beanstalk/Bastion) → DB-only subnets
- **Database**: Private DB-only subnets, only accessible from Beanstalk or Bastion
- **Beanstalk**: Private subnet, only reachable via ALB or SSM bastion tunnel
- **Bastion**: Private subnet, accessible only via:
  - NLB port forwarding (for VPN clients connecting to vpn.abc.com)
  - AWS Systems Manager Session Manager (for direct SSH-less access)
- **VPN**: Encrypted OpenVPN tunnel (UDP 1194), self-signed PKI, client certs validated
- **Public Load Balancers**: ALB (API) and NLB (VPN gateway) are the only resources in public subnets
- **Certificate Management**: ACM (auto-renewing, no manual rotation)
- **Logging**: ALB access logs → S3, CloudTrail for API calls, X-Ray for traces

## Cost Breakdown (Typical Production)

| Component | Instance Type | Monthly Cost |
|-----------|---------------|--------------|
| RDS Aurora | db.t3.small | ~$36.50 |
| NAT Gateway | 1x | ~$32.00 |
| ALB | Standard | ~$16.00 |
| Beanstalk (2x) | t3.small | ~$60.00 |
| Bastion | t3.micro | ~$7.50 |
| Storage (S3, logs) | Variable | ~$5.00 |
| X-Ray traces | Per TB | ~$5.00 |
| **Total** | | **~$161.50/month** |

To minimize: destroy dev environment when idle, use t3.micro in dev, reduce X-Ray sampling.
