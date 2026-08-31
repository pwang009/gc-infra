provider "aws" {
  region = var.region
}

# Lightsail WordPress Instance
resource "aws_lightsail_instance" "wordpress" {
  name              = var.instance_name
  availability_zone = var.availability_zone
  blueprint_id      = var.blueprint_id
  bundle_id         = var.bundle_id
  key_pair_name     = var.key_pair_name

  tags = merge(
    {
      Name        = var.instance_name
      Environment = var.environment
      Project     = "goodconnex"
      Service     = "marketing-wordpress"
    },
    var.tags
  )
}

# Static IP for the Lightsail Instance
resource "aws_lightsail_static_ip" "wordpress" {
  name = "${var.instance_name}-static-ip"
}

# Attach Static IP to Instance
resource "aws_lightsail_static_ip_attachment" "wordpress" {
  static_ip_name = aws_lightsail_static_ip.wordpress.id
  instance_name  = aws_lightsail_instance.wordpress.id
}

# Firewall / Public Ports Configuration
resource "aws_lightsail_instance_public_ports" "wordpress" {
  instance_name = aws_lightsail_instance.wordpress.name

  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
  }

  port_info {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
  }

  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidrs     = var.allowed_ssh_cidrs
  }
}
