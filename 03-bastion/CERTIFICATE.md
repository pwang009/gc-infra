# Let's Encrypt Certificate Configuration for OpenVPN Bastion

This guide documents the manual steps required to configure Let's Encrypt SSL/TLS certificates for the OpenVPN Bastion server after Terraform deployment.

## Architecture Overview

- **NLB**: TCP passthrough (no TLS termination) on ports 443, 943, 1194
- **EC2 Instance**: Nginx + OpenVPN with Let's Encrypt certificates
- **Certificate Source**: Let's Encrypt (free, auto-renewable)
- **Domain**: Hosted on GoDaddy

## Prerequisites

1. **Domain registered with GoDaddy** (e.g., `vpn.yourdomain.com`)
2. **Terraform deployment completed** (EC2 instance running)
3. **SSH access** to bastion EC2 instance
4. **Bastion instance must be in a public subnet** (for Certbot standalone validation)

## Step-by-Step Instructions

### 1. Get NLB DNS Name / Elastic IP

After Terraform deployment, get the NLB endpoint:

```bash
cd /home/tony/projects/gc/terraform/03-bastion
terraform output
```

Look for the NLB output. You should see something like:
```
nlb_dns_name = "dev-vpn-nlb-xxxxxxxx.elb.us-west-1.amazonaws.com"
nlb_ip = "xxx.xxx.xxx.xxx"  (if Elastic IP is attached)
```

Note: The NLB IP/DNS is in a public subnet and should be publicly accessible.

### 2. Update GoDaddy DNS Records

1. Log in to **GoDaddy account**
2. Navigate to **Domain Management** → DNS settings for `yourdomain.com`
3. **Create an A record**:
   - Name: `vpn` (or your subdomain)
   - Type: `A`
   - Value: NLB Elastic IP or use CNAME with NLB DNS name
   - TTL: 600 (10 minutes, for faster propagation)

Example:
```
Name: vpn
Type: A
Value: 203.0.113.45  (NLB Elastic IP)
```

4. **Wait for DNS propagation** (2-5 minutes typically)
5. **Verify DNS resolution**:
   ```bash
   nslookup vpn.yourdomain.com
   # Should return the NLB IP
   ```

### 3. Access Bastion EC2 Instance via SSM Session Manager

Get the bastion instance ID:

```bash
# Find the instance ID
aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=gc-bastion-dev" \
  --query 'Reservations[0].Instances[0].InstanceId' \
  --region us-west-1
```

Start an SSM session:

```bash
aws ssm start-session --target <INSTANCE_ID> --region us-west-1
```

You should now have a shell prompt on the bastion instance.

### 4. Obtain Let's Encrypt Certificate with Certbot

Once SSH'd into the bastion instance:

```bash
# Switch to root
sudo su -

# Run Certbot in standalone mode
certbot certonly --standalone \
  -d vpn.yourdomain.com \
  --agree-tos \
  -m your-email@example.com \
  --non-interactive

# You should see:
# Successfully received certificate.
# Certificate is saved at: /etc/letsencrypt/live/vpn.yourdomain.com/fullchain.pem
# Key is saved at: /etc/letsencrypt/live/vpn.yourdomain.com/privkey.pem
```

**Note**: Certbot will briefly start a web server on port 80 to validate domain ownership.

#### Troubleshooting Certbot

If Certbot fails:

1. **Port 80 not accessible from internet**:
   - Ensure EC2 security group allows inbound 80 from 0.0.0.0/0
   - Check NLB has listener on port 80 (it doesn't currently - you may need to add one)

2. **DNS not propagated**:
   - Wait longer and retry
   - Test DNS: `nslookup vpn.yourdomain.com`

3. **Domain already has certificate**:
   - Remove old one first: `certbot delete --cert-name vpn.yourdomain.com`

### 5. Update Nginx Configuration

Nginx config template is at `/etc/nginx/conf.d/openvpn-client.conf` and references a placeholder domain.

Update the Nginx config with your actual domain:

```bash
sudo sed -i 's|YOUR_DOMAIN|vpn.yourdomain.com|g' /etc/nginx/conf.d/openvpn-client.conf
```

**Verify the file looks correct**:

```bash
sudo cat /etc/nginx/conf.d/openvpn-client.conf
```

Should show:
```nginx
server {
    listen 443 ssl http2;
    server_name _;
    
    ssl_certificate /etc/letsencrypt/live/vpn.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/vpn.yourdomain.com/privkey.pem;
    
    location / {
        root /var/www/html;
        index index.html;
    }
    
    location /client.ovpn {
        alias /etc/openvpn/client.ovpn;
        add_header Content-Disposition "attachment; filename=client.ovpn";
    }
}
```

### 6. Test Nginx Configuration

```bash
sudo nginx -t
# Should output: "nginx: configuration syntax is ok"
```

### 7. Reload Nginx

```bash
sudo systemctl reload nginx
```

### 8. Verify HTTPS is Working

From your local machine:

```bash
# Test HTTPS on port 443 (client profile download)
curl -I https://vpn.yourdomain.com:443

# Should return 200 OK and valid certificate info

# Test HTTPS on port 943 (OpenVPN admin)
# Note: This requires OpenVPN web UI configuration
curl -I https://vpn.yourdomain.com:943
```

### 9. Configure OpenVPN for HTTPS (Optional)

If you want the OpenVPN admin interface on port 943 to use the same Let's Encrypt certificate:

Edit `/etc/openvpn/server.conf` to add:

```bash
# OpenVPN web UI configuration (port 943)
# This requires additional setup - consult OpenVPN documentation
```

Alternatively, use a reverse proxy (Nginx) to handle port 943 with SSL.

## Maintenance

### Auto-Renewal

Certbot automatically renews certificates before expiry. Verify the renewal timer is active:

```bash
sudo systemctl status certbot.timer
# Should be "active and running"
```

### Manual Renewal

To manually renew (not normally needed):

```bash
sudo certbot renew --dry-run  # Test renewal
sudo certbot renew             # Actually renew
```

### Certificate Expiry

Check certificate expiration:

```bash
sudo certbot certificates
# Lists all certificates and expiry dates
```

## Health Checks

The NLB health checks on port 943 (TCP). Ensure OpenVPN or a service is listening:

```bash
# Check OpenVPN is running
sudo systemctl status openvpn-server@server

# Check Nginx is running
sudo systemctl status nginx

# Verify ports are listening
sudo netstat -tlnp | grep -E ':(80|443|943|1194)'
```

Expected output:
```
tcp  0  0 0.0.0.0:80      0.0.0.0:*  LISTEN   (nginx)
tcp  0  0 0.0.0.0:443     0.0.0.0:*  LISTEN   (nginx)
tcp  0  0 0.0.0.0:943     0.0.0.0:*  LISTEN   (openvpn or service)
udp  0  0 0.0.0.0:1194    0.0.0.0:*            (openvpn)
```

## Accessing the VPN

### Download Client Profile

```bash
curl -k https://vpn.yourdomain.com:443/client.ovpn -o client.ovpn
```

### Connect to VPN

```bash
openvpn --config client.ovpn
```

## Troubleshooting

### "Connection refused" on port 943 or 443

1. Verify the service is running:
   ```bash
   sudo systemctl status openvpn-server@server
   sudo systemctl status nginx
   ```

2. Restart services if needed:
   ```bash
   sudo systemctl restart openvpn-server@server
   sudo systemctl restart nginx
   ```

3. Check firewall/security groups:
   ```bash
   # Verify EC2 allows inbound on 80, 443, 943, 1194
   aws ec2 describe-security-groups \
     --group-ids <SG_ID> \
     --region us-west-1 \
     --query 'SecurityGroups[0].IpPermissions'
   ```

### Certificate not found

If Nginx shows certificate not found:

```bash
# List installed certificates
sudo certbot certificates

# Manually specify certificate paths in Nginx config if needed
ls -la /etc/letsencrypt/live/
```

### DNS not resolving

Wait 5-10 minutes after updating GoDaddy DNS. Verify:

```bash
# Clear local DNS cache (on local machine)
# Mac:
sudo dscacheutil -flushcache

# Linux:
sudo systemctl restart systemd-resolved

# Windows:
ipconfig /flushdns
```

## Support

- **Certbot Docs**: https://certbot.eff.org/docs/
- **Let's Encrypt**: https://letsencrypt.org/
- **OpenVPN**: https://openvpn.net/community-documentation/
- **Terraform**: `terraform output` to view all outputs from the deployment
