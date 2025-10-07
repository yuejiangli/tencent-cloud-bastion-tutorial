#!/bin/bash

# Bastion Host Initialization Script
# This script configures security, monitoring, and management tools
set -e

# Update system packages
apt-get update -y
apt-get upgrade -y

# Set hostname from Terraform variable
hostnamectl set-hostname ${hostname}
echo "127.0.0.1 ${hostname}" >> /etc/hosts

# Install essential packages and security tools
apt-get install -y \
    curl \
    wget \
    vim \
    htop \
    net-tools \
    telnet \
    nmap \
    tcpdump \
    tree \
    unzip \
    jq \
    awscli \
    fail2ban \
    ufw

# Configure SSH security hardening
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Configure UFW firewall
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow from 10.0.0.0/16

# Configure and start fail2ban for intrusion prevention
systemctl enable fail2ban
systemctl start fail2ban

# Restart SSH service to apply security configurations
systemctl restart sshd

# Create bastion logging directory
mkdir -p /var/log/bastion
chown ubuntu:ubuntu /var/log/bastion

# Configure SSH session logging
cat >> /etc/ssh/sshd_config << 'EOF'

# Bastion Host session logging configuration
LogLevel VERBOSE
EOF

# Create welcome message (MOTD)
cat > /etc/motd << 'EOF'
*****************************************************
*                                                   *
*           Welcome to Bastion Host                 *
*                                                   *
*    This server provides secure access to          *
*    private network resources                       *
*                                                   *
*    All activities are logged and audited          *
*                                                   *
*    Please follow company security policies        *
*                                                   *
*****************************************************
EOF

# Install CloudWatch agent (optional - commented out)
# wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb
# dpkg -i -E ./amazon-cloudwatch-agent.deb

# Create bastion management script
cat > /usr/local/bin/bastion-status << 'EOF'
#!/bin/bash
echo "=== Bastion Host Status Check ==="
echo "Hostname: $(hostname)"
echo "System Time: $(date)"
echo "System Load: $(uptime)"
echo "Memory Usage: $(free -h)"
echo "Disk Usage: $(df -h /)"
echo "Network Connections: $(ss -tuln | wc -l) connections"
echo "Active Users: $(who | wc -l) users"
echo "================================="
EOF

chmod +x /usr/local/bin/bastion-status

# Restart services to apply all configurations
systemctl restart sshd
systemctl restart fail2ban

# Log initialization completion
echo "$(date): Bastion host initialization completed" >> /var/log/bastion/init.log

echo "Bastion host initialization completed successfully"