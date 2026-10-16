# RDS Aurora PostgreSQL Connection Guide

This guide covers secure database connection patterns using **AWS RDS IAM Database Authentication** for both the application runtime (Option 3: Zero-Password IAM Auth) and developer database clients like DBeaver (Method 1: Manual IAM Token and Method 3: 1-Click Helper Script).

---

## Part 1: Application Connection via RDS IAM Authentication (Option 3 - Zero Static Password)

With **RDS IAM Database Authentication**, no static database password exists in code, environment variables, or configuration files. Instead, the application generates a temporary, cryptographically-signed 15-minute IAM authentication token at runtime using the EC2 instance's IAM role.

### Architecture Overview

```
┌─────────────────────────────────┐
│ Elastic Beanstalk EC2 Instance  │
│ (Assumes IAM Instance Profile)  │
└────────────────┬────────────────┘
                 │
                 │ 1. Generates 15-min IAM DB Auth Token (boto3)
                 │    Token signed with instance IAM credentials
                 ▼
┌─────────────────────────────────┐
│ Python Application Engine       │
│ (SQLAlchemy / psycopg2 / asyncpg│
└────────────────┬────────────────┘
                 │
                 │ 2. Connects using:
                 │    - Username: <dbuser>
                 │    - Password: <IAM_AUTH_TOKEN>
                 │    - SSL/TLS: require
                 ▼
┌─────────────────────────────────┐
│ AWS RDS Aurora PostgreSQL       │
│ (Validates token against AWS IAM│
└─────────────────────────────────┘
```

---

### 1. Enable IAM Database Authentication on Aurora (Terraform)

In `02-db/rds.tf`, ensure IAM database authentication is enabled on the cluster:

```hcl
resource "aws_rds_cluster" "aurora" {
  cluster_identifier              = "${var.environment}-aurora-cluster"
  engine                          = "aurora-postgresql"
  ...
  iam_database_authentication_enabled = true
}
```

---

### 2. Grant Database User `rds_iam` Role in PostgreSQL

Connect to the PostgreSQL database as admin and create or alter the application database user to authenticate via AWS IAM:

```sql
-- Create user if not exists
CREATE USER <dbuser> WITH LOGIN;

-- Grant AWS IAM authentication role
GRANT rds_iam TO <dbuser>;

-- Grant required database permissions
GRANT ALL PRIVILEGES ON DATABASE <dbname> TO <dbuser>;
GRANT ALL ON SCHEMA public TO <dbuser>;
```

---

### 3. Grant IAM Permission to the Elastic Beanstalk EC2 Role

In `03-ebs-v1/iam.tf`, add an IAM policy allowing the Beanstalk EC2 role (`prod-aws-elasticbeanstalk-ec2-role`) to connect via `rds-db:connect`:

```hcl
resource "aws_iam_role_policy" "rds_iam_connect" {
  name = "${var.environment}-beanstalk-rds-iam-connect"
  role = aws_iam_role.eb_ec2_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds-db:connect"
        ]
        # Format: arn:aws:rds-db:<region>:<account_id>:dbuser:<db_cluster_resource_id>/<db_username>
        Resource = "arn:aws:rds-db:${var.aws_region}:<aws_account_id>:dbuser:${data.terraform_remote_state.db.outputs.cluster_resource_id}/<dbuser>"
      }
    ]
  })
}
```

---

### 4. Application Integration in Python (SQLAlchemy / psycopg2)

Because the IAM token expires after 15 minutes for *new* connection handshakes, configure SQLAlchemy connection pool event listeners to generate a fresh token dynamically whenever a new connection is opened from the pool:

```python
import os
import boto3
from sqlalchemy import create_engine, event
from sqlalchemy.orm import sessionmaker

DB_HOST = os.environ.get("DBURL", "<db-proxy-endpoint>")
DB_PORT = int(os.environ.get("DBPORT", "5432"))
DB_NAME = os.environ.get("DBNAME", "<dbname>")
DB_USER = os.environ.get("DBUSER", "<dbuser>")
AWS_REGION = os.environ.get("AWS_REGION", "us-west-2")

rds_client = boto3.client("rds", region_name=AWS_REGION)

def generate_auth_token():
    """Generates a temporary IAM database authentication token."""
    return rds_client.generate_db_auth_token(
        DBHostname=DB_HOST,
        Port=DB_PORT,
        DBUsername=DB_USER,
        Region=AWS_REGION,
    )

# Base connection string with sslmode=require
DATABASE_URL = f"postgresql+psycopg2://{DB_USER}@{DB_HOST}:{DB_PORT}/{DB_NAME}?sslmode=require"

engine = create_engine(
    DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_recycle=900,  # Recycle connections before 15 min token expiry
    pool_pre_ping=True,
)

# Intercept connection creation to inject fresh IAM token as the password
@event.listens_for(engine, "do_connect")
def provide_token(dialect, conn_rec, cargs, cparams):
    cparams["password"] = generate_auth_token()

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
```

---

### 5. Elastic Beanstalk Environment Properties

In `15-ebs-conf`, `DBPASSWORD` is completely removed:

```hcl
env_properties = {
  DBURL              = local.db_url
  DBUSER             = local.db_user
  DBNAME             = local.db_name
  AUTH_MODE          = var.auth_mode
  COGNITO_REGION     = local.cognito_region
  CORS_ALLOW_ORIGINS = var.cors_allow_origins
  # No DBPASSWORD needed!
}
```

---

## Part 2: DBeaver Client Connection via RDS IAM Authentication (Method 1)

With AWS RDS IAM Database Authentication enabled, database users can connect without a static database password by generating a temporary 15-minute IAM authentication token.

### Prerequisites

1. Ensure the PostgreSQL user exists with `rds_iam` role granted:
   ```sql
   CREATE USER <dbuser> WITH LOGIN;
   GRANT rds_iam TO <dbuser>;
   ```
2. Ensure your local AWS CLI is authenticated (`aws sts get-caller-identity`).

### Step 1: Generate IAM Token via AWS CLI

Run the following command in your terminal:

```bash
aws rds generate-db-auth-token \
  --hostname <aurora-cluster-endpoint> \
  --port 5432 \
  --username <dbuser> \
  --region us-west-2
```

The output will be a temporary signed authentication token.

### Step 2: Configure DBeaver Connection

1. Open **DBeaver** $\rightarrow$ **New Database Connection** $\rightarrow$ **PostgreSQL**.
2. **Main Tab**:
   - **Host**: `<aurora-cluster-endpoint>` (or `localhost` if using Bastion/SSM port forwarding)
   - **Port**: `5432`
   - **Database**: `<dbname>`
   - **Authentication**: `Database Native`
   - **Username**: `<dbuser>`
   - **Password**: *(Paste the IAM token string from Step 1)*
3. **SSL Tab**:
   - Check **Use SSL**.
   - Set **SSL mode** to **`require`** *(IAM auth requires SSL/TLS)*.
4. Click **Test Connection** and connect.

> **Note**: The token is only needed when establishing the initial connection. Once connected, your DBeaver session remains active until disconnected.

---

## Part 3: 1-Click AWS CLI DBeaver Helper Script (Method 3)

To avoid manually running the AWS CLI command and copying/pasting tokens each time, use this 1-click helper script to automatically generate the token and place it directly into your system clipboard.

### Helper Script: `get-db-token.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Configuration
DB_HOST="${DB_HOST:-<aurora-cluster-endpoint>}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-<dbuser>}"
AWS_REGION="${AWS_REGION:-us-west-2}"

echo "Generating RDS IAM Auth Token for ${DB_USER}@${DB_HOST}:${DB_PORT}..."

TOKEN=$(aws rds generate-db-auth-token \
  --hostname "$DB_HOST" \
  --port "$DB_PORT" \
  --username "$DB_USER" \
  --region "$AWS_REGION")

# Copy to clipboard depending on OS
if command -v pbcopy &>/dev/null; then
  # macOS
  echo -n "$TOKEN" | pbcopy
  echo "✅ Token generated and copied to macOS clipboard!"
elif command -v xclip &>/dev/null; then
  # Linux (X11)
  echo -n "$TOKEN" | xclip -selection clipboard
  echo "✅ Token generated and copied to Linux clipboard (xclip)!"
elif command -v wl-copy &>/dev/null; then
  # Linux (Wayland)
  echo -n "$TOKEN" | wl-copy
  echo "✅ Token generated and copied to Wayland clipboard (wl-copy)!"
elif command -v clip.exe &>/dev/null; then
  # Windows WSL
  echo -n "$TOKEN" | clip.exe
  echo "✅ Token generated and copied to Windows clipboard!"
else
  echo "⚠️ Clipboard utility not found. Here is your token:"
  echo ""
  echo "$TOKEN"
fi

echo ""
echo "👉 Paste the token into the Password field in DBeaver and connect within 15 minutes."
```

### Usage

1. Make the script executable:
   ```bash
   chmod +x get-db-token.sh
   ```
2. Run the script:
   ```bash
   ./get-db-token.sh
   ```
3. Switch to DBeaver, press `Ctrl+V` (or `Cmd+V` on macOS) in the Password field, and connect.
