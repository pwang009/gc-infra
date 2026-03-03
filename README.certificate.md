# GET A CUSTOM DOMAIN CERTIFICATE

## send the request
```bash
# aws acm request-certificate --domain-name api.lishanteala.com --validation-method DNS --region us-west-1
aws acm request-certificate --domain-name vpn.lishanteala.com --validation-method DNS --region us-west-1
```

## changes in godaddy.com
- add a CNAME
- name: _d7efe80df29caba041d7b0cc5868ec6e.api.lishanteala.com.
- value: _49a39449d0c1f66ff9800b12059f323a.jkddzztszm.acm-validations.aws.

in godaddy, it will display _d7efe80df29caba041d7b0cc5868ec6e.api as name

## changes added to environment.tf file
- associate certificate to alb
- port forwarding from 80 to 443
- run terraform apply
---

# VPN CERTIFICATE SETUP (vpn.abc.com)

## Request ACM certificate for VPN domain

```bash
aws acm request-certificate --domain-name vpn.abc.com --validation-method DNS --region us-west-1
```

This will return a **Certificate ARN** (format: `arn:aws:acm:us-west-1:ACCOUNT_ID:certificate/CERTIFICATE_ID`) and provide DNS validation details.

## Add CNAME record in GoDaddy

AWS Certificate Manager will provide a CNAME record to add in GoDaddy DNS:
- In GoDaddy DNS settings, add a CNAME record with the provided name and value
- Wait for validation (usually a few minutes)
- Once validated, the certificate status in ACM console will show "Success"

## Update Terraform with certificate ARN

Once the certificate is validated, copy the **Certificate ARN** and update both files:

**03-bastion/prod.tfvars:**
```hcl
certificate_arn = "arn:aws:acm:us-west-1:ACCOUNT_ID:certificate/CERTIFICATE_ID"
```

**03-bastion/dev.tfvars:**
```hcl
certificate_arn = "arn:aws:acm:us-west-1:ACCOUNT_ID:certificate/CERTIFICATE_ID"
```

## Deploy NLB with TLS listeners

Run terraform apply in the 03-bastion folder:

```bash
cd 03-bastion
terraform apply -var-file=prod.tfvars
```

The NLB will now:
- Terminate TLS on port 443 (client profile download) with auto-renewing certificate
- Terminate TLS on port 943 (OpenVPN admin portal) with auto-renewing certificate
- Forward UDP 1194 (VPN tunnel) to the bastion instance

## GoDaddy DNS: Point vpn.abc.com to NLB

Add an A record (or CNAME) in GoDaddy pointing `vpn.abc.com` to the NLB's public DNS name (available in Terraform output: `nlb_dns_name`).

Clients can now connect using `vpn.abc.com:1194` instead of the bastion public IP.
