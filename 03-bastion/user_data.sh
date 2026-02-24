#!/bin/bash
set -e

# Update system
yum update -y

# Install MySQL client for database access from bastion
yum install -y mariadb105-client

# Optional: Install CloudWatch agent for monitoring (useful for bastion hosts)
yum install -y amazon-cloudwatch-agent

# Configure basic CloudWatch monitoring for the bastion host
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<'EOF'
{
  "metrics": {
    "metrics_collected": {
      "mem": {
        "measurement": [
          {"name": "mem_used_percent", "rename": "MemoryUtilization", "unit": "Percent"}
        ]
      },
      "disk": {
        "measurement": [
          {"name": "disk_used_percent", "rename": "DiskUtilization", "unit": "Percent"}
        ],
        "resources": ["/"]
      },
      "cpu": {
        "measurement": [
          {"name": "cpu_usage_idle", "rename": "CPUUtilization", "unit": "Percent", "calcuation": "cpu_usage_total - cpu_usage_idle"}
        ]
      }
    }
  }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Signal completion
echo "Bastion host setup completed successfully" > /var/log/userdata.log
