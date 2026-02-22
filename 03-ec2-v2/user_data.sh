#!/bin/bash
set -e

# Update system
yum update -y

# Install Java 21 JRE (headless, production-optimized)
yum install -y java-21-amazon-corretto-headless

# Install CloudWatch agent for logging
yum install -y amazon-cloudwatch-agent

# Install MySQL client
yum install -y mariadb105

# Create app directory
mkdir -p /opt/app
chown ec2-user:ec2-user /opt/app

# Download JAR from S3
aws s3 cp s3://${S3_BUCKET}/${ENVIRONMENT}/app.jar /opt/app/app.jar
chown ec2-user:ec2-user /opt/app/app.jar

# Configure CloudWatch Logs
cat > /opt/aws/amazon-cloudwatch-agent/etc/config.json <<'EOF'
{
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [{
          "file_path": "/var/log/app.log",
          "log_group_name": "/aws/ec2/${ENVIRONMENT}-api",
          "log_stream_name": "{instance_id}"
        }]
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

# Create systemd service for the API
cat > /etc/systemd/system/api.service <<'EOF'
[Unit]
Description=REST API Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
ExecStart=/usr/bin/java -jar /opt/app/app.jar --server.servlet.context-path=/v1
Restart=always
RestartSec=10
StandardOutput=append:/var/log/app.log
StandardError=append:/var/log/app.log

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
systemctl daemon-reload
systemctl enable api
systemctl start api

# Signal completion
echo "User data script completed successfully" > /var/log/userdata.log
