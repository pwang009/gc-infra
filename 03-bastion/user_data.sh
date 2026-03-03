#!/bin/bash
set -euo pipefail

# Update system and install utilities
yum update -y
yum install -y mariadb105-client amazon-cloudwatch-agent openvpn easy-rsa nginx certbot python3-certbot-nginx

# Configure CloudWatch monitoring
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
          {"name": "cpu_usage_idle", "rename": "CPUUtilization", "unit": "Percent"}
        ]
      }
    }
  }
}
EOF

/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  -a fetch-config \
  -m ec2 \
  -s \
  -c file:/opt/aws/amazon-cloudwatch-agent/etc/config.json

# Enable IP forwarding for OpenVPN routing
sysctl -w net.ipv4.ip_forward=1
sed -i '/^net.ipv4.ip_forward/s/0/1/' /etc/sysctl.conf || echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

# Setup easy-rsa and generate certificates (non-interactive)
EASYRSA_DIR=/etc/openvpn/easy-rsa
mkdir -p ${EASYRSA_DIR}
cp -r /usr/share/easy-rsa/ /usr/share/easy-rsa.orig
cp -r /usr/share/easy-rsa/* ${EASYRSA_DIR}/
pushd ${EASYRSA_DIR}
./easyrsa init-pki
EASYRSA_BATCH=1 ./easyrsa --req-cn="gc-bastion-openvpn-ca" build-ca nopass
EASYRSA_BATCH=1 ./easyrsa gen-dh
EASYRSA_BATCH=1 ./easyrsa build-server-full gc-bastion-server nopass
EASYRSA_BATCH=1 ./easyrsa build-client-full bastion-client nopass
popd

# Create OpenVPN server configuration
cat > /etc/openvpn/server.conf <<'EOF'
port 1194
proto udp
dev tun
ca ${EASYRSA_DIR}/pki/ca.crt
cert ${EASYRSA_DIR}/pki/issued/gc-bastion-server.crt
key ${EASYRSA_DIR}/pki/private/gc-bastion-server.key
dh ${EASYRSA_DIR}/pki/dh.pem
server 172.20.1.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn/ipp.txt
push "route 10.66.0.0 255.255.0.0"
keepalive 10 120
cipher AES-256-GCM
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn/status.log
log-append /var/log/openvpn/openvpn.log
verb 3
EOF

# Ensure log directories exist
mkdir -p /var/log/openvpn

# MASQUERADE VPN traffic into the VPC
iptables -t nat -A POSTROUTING -s 172.20.1.0/24 -o eth0 -j MASQUERADE

# Enable OpenVPN service
systemctl enable --now openvpn-server@server

# Setup Nginx for HTTPS web services
mkdir -p /var/www/html
cat > /var/www/html/index.html <<'EOF'
<!DOCTYPE html>
<html>
<head><title>OpenVPN Bastion</title></head>
<body><h1>OpenVPN Bastion</h1><p>Access admin: https://your-domain.com:943</p></body>
</html>
EOF

# Create Nginx configuration for port 443 (client profile download)
cat > /etc/nginx/conf.d/openvpn-client.conf <<'EOF'
server {
    listen 443 ssl http2;
    server_name _;
    
    ssl_certificate /etc/letsencrypt/live/YOUR_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/YOUR_DOMAIN/privkey.pem;
    
    location / {
        root /var/www/html;
        index index.html;
    }
    
    # Serve OpenVPN client profile
    location /client.ovpn {
        alias /etc/openvpn/client.ovpn;
        add_header Content-Disposition "attachment; filename=client.ovpn";
    }
}
EOF

# Start Nginx (will fail until certificates are installed, but that's OK)
systemctl enable nginx || true
systemctl start nginx || true

# Note: User should manually run Certbot after getting the domain/NLB IP:
# certbot certonly --standalone -d your-domain.com
# Then update Nginx config with the certificate paths and reload

# Export client configuration for later retrieval
CLIENT_OVPN=/etc/openvpn/client.ovpn
cat > ${CLIENT_OVPN} <<'EOF'
client
dev tun
proto udp
remote $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4) 1194
resolv-retry infinite
nobind
persist-key
persist-tun
verb 3
<ca>
$(cat ${EASYRSA_DIR}/pki/ca.crt)
</ca>
<cert>
$(cat ${EASYRSA_DIR}/pki/issued/bastion-client.crt)
</cert>
<key>
$(cat ${EASYRSA_DIR}/pki/private/bastion-client.key)
</key>
EOF

# Final log entry
echo "Bastion host setup completed successfully" > /var/log/userdata.log
