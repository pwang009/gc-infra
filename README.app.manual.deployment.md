# Manual Application Deployment Guide

This guide is for when the user_data script fails and the API service needs to be set up manually.

## Prerequisites

- JAR file uploaded to S3: `s3://gc-app-deployments-c8f7ewhysy5a/dev/app.jar`
- SSH/SSM access to EC2 instance

## Step 1: Connect to EC2 Instance

```bash
# Get instance ID
aws ec2 describe-instances \
  --filters "Name=tag:Environment,Values=dev" "Name=instance-state-name,Values=running" \
  --query 'Reservations[].Instances[].[InstanceId,Tags[?Key==`Name`].Value|[0]]' \
  --output table

# Connect via SSM
aws ssm start-session --target i-xxxxxxxxxxxxxxxxx
```

## Step 2: Download JAR from S3

```bash
# Create app directory
sudo mkdir -p /opt/app

# Download JAR from S3
sudo aws s3 cp s3://gc-app-deployments-c8f7ewhysy5a/dev/app.jar /opt/app/app.jar

# Set proper ownership
sudo chown ec2-user:ec2-user /opt/app/app.jar

# Verify JAR exists
ls -lh /opt/app/app.jar
```

## Step 3: Create Systemd Service

```bash
# Create the systemd service file
sudo tee /etc/systemd/system/api.service > /dev/null <<'EOF'
[Unit]
Description=REST API Service
After=network.target

[Service]
Type=simple
User=ec2-user
WorkingDirectory=/opt/app
ExecStart=/usr/bin/java -jar /opt/app/app.jar
Restart=always
RestartSec=10
StandardOutput=append:/var/log/app.log
StandardError=append:/var/log/app.log

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions on service file
sudo chmod 644 /etc/systemd/system/api.service
```

## Step 4: Start the Service

```bash
# Reload systemd to recognize new service
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable api

# Start the service
sudo systemctl start api

# Check service status
sudo systemctl status api
```

## Step 5: Verify Application is Running

```bash
# Check if service is active
sudo systemctl is-active api

# View application logs
sudo tail -f /var/log/app.log

# Test the API endpoint
curl http://localhost:8080

# Check if port 8080 is listening
sudo netstat -tlnp | grep 8080
```

## Troubleshooting

### Check if Java is installed
```bash
java -version
# Should show: openjdk version "21.x.x"
```

### If Java is not installed
```bash
sudo yum install -y java-21-amazon-corretto-headless
```

### View service logs
```bash
# View recent logs
sudo journalctl -u api -n 50

# Follow logs in real-time
sudo journalctl -u api -f
```

### Restart the service
```bash
sudo systemctl restart api
sudo systemctl status api
```

### Stop the service
```bash
sudo systemctl stop api
```

### Check user_data execution logs
```bash
# View cloud-init logs to see why user_data failed
sudo cat /var/log/cloud-init-output.log

# Check for errors
sudo grep -i error /var/log/cloud-init-output.log
```

## Updating the Application

When you need to deploy a new version:

```bash
# 1. Upload new JAR to S3 (from local machine)
aws s3 cp target/app.jar s3://gc-app-deployments-c8f7ewhysy5a/dev/app.jar

# 2. On EC2, download new JAR
sudo aws s3 cp s3://gc-app-deployments-c8f7ewhysy5a/dev/app.jar /opt/app/app.jar
sudo chown ec2-user:ec2-user /opt/app/app.jar

# 3. Restart service
sudo systemctl restart api

# 4. Verify
sudo systemctl status api
curl http://localhost:8080/greeting?name=Tony
```

## Common Issues

### Issue: Service fails to start
**Solution:** Check logs for errors
```bash
sudo journalctl -u api -n 100 --no-pager
```

### Issue: Port 8080 already in use
**Solution:** Find and kill the process
```bash
sudo lsof -i :8080
sudo kill -9 <PID>
sudo systemctl start api
```

### Issue: Permission denied on JAR file
**Solution:** Fix ownership
```bash
sudo chown ec2-user:ec2-user /opt/app/app.jar
sudo chmod 644 /opt/app/app.jar
```

### Issue: Out of memory
**Solution:** Check instance size and Java heap settings
```bash
# Check memory
free -h

# Modify service to set heap size
sudo systemctl edit api
# Add: Environment="JAVA_OPTS=-Xmx512m"
```
