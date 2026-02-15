## IAM SSM Access Control

This module creates IAM policies and groups to control SSM access to EC2 instances.

### What it does:
- Creates IAM policy that restricts SSM access by:
  - Environment tag (dev/prod)
  - Source IP address
- Creates IAM group for SSM users
- Attaches policy to group

### Deployment

**Dev:**
```bash
cd 06-iam-ssm-access
terraform init -backend-config="key=dev/iam-ssm-access/terraform.tfstate"
terraform plan -var-file=dev.tfvars
terraform apply -var-file=dev.tfvars
```

**Prod:**
```bash
cd 06-iam-ssm-access
terraform init -backend-config="key=prod/iam-ssm-access/terraform.tfstate"
terraform plan -var-file=prod.tfvars
terraform apply -var-file=prod.tfvars
```

### Adding Users

**Add IAM user to the group:**
```bash
aws iam add-user-to-group \
  --user-name john.doe \
  --group-name dev-ssm-users
```

**Or via Terraform:**
```hcl
resource "aws_iam_user_group_membership" "john" {
  user = "john.doe"
  groups = [aws_iam_group.ssm_users.name]
}
```

### Testing Access

**From allowed IP:**
```bash
aws ssm start-session --target i-xxxxxxxxx
# Should work
```

**From different IP:**
```bash
aws ssm start-session --target i-xxxxxxxxx
# Should fail with access denied
```

### Updating Allowed IPs

Edit `dev.tfvars` or `prod.tfvars`:
```hcl
allowed_source_ips = [
  "70.181.86.188/32",
  "203.0.113.0/24",
  "198.51.100.10/32"
]
```

Then apply:
```bash
terraform apply -var-file=dev.tfvars
```
