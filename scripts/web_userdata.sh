#!/bin/bash

# Web Server Initialization Script
# This script sets up Nginx web server with basic configuration
set -e

# Update system packages
apt-get update -y
apt-get upgrade -y

# Set hostname from Terraform variable
hostnamectl set-hostname ${hostname}
echo "127.0.0.1 ${hostname}" >> /etc/hosts

# Install essential packages
apt-get install -y \
    curl \
    wget \
    vim \
    htop \
    net-tools \
    nginx \
    ufw

# Configure UFW firewall for web server
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 'Nginx Full'
ufw allow from 10.0.0.0/16

# Start and enable Nginx service
systemctl start nginx
systemctl enable nginx

# Create custom web page with server information
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Web Server Status</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background-color: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header {
            color: #333;
            text-align: center;
            margin-bottom: 30px;
        }
        .info {
            background: #e8f4fd;
            padding: 15px;
            border-radius: 5px;
            margin: 10px 0;
        }
        .status {
            color: #28a745;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1 class="header">🌐 Web Server Status</h1>
        
        <div class="info">
            <h3>Server Information</h3>
            <p><strong>Hostname:</strong> <span id="hostname">${hostname}</span></p>
            <p><strong>Status:</strong> <span class="status">✅ Online</span></p>
            <p><strong>Server Time:</strong> <span id="datetime">$${new Date().toLocaleString()}</span></p>
            <p><strong>OS:</strong> <span id="os">$${os.hostname()}</span></p>
        </div>
        
        <div class="info">
            <h3>Network Information</h3>
            <p><strong>Private Network:</strong> 10.0.0.0/16</p>
            <p><strong>Access Method:</strong> Via Bastion Host</p>
            <p><strong>Security:</strong> Firewall Enabled</p>
        </div>
        
        <div class="info">
            <h3>Service Status</h3>
            <p><strong>Web Server:</strong> <span class="status">✅ Nginx Running</span></p>
            <p><strong>Firewall:</strong> <span class="status">✅ UFW Active</span></p>
            <p><strong>SSH:</strong> <span class="status">✅ Secure Access Only</span></p>
        </div>
        
        <div class="info">
            <h3>Access Information</h3>
            <p><strong>HTTP:</strong> Port 80 (Internal Network Only)</p>
            <p><strong>SSH:</strong> Port 22 (Bastion Host Access Only)</p>
            <p><strong>Management:</strong> Via Bastion Host Jump Server</p>
        </div>
    </div>
    
    <script>
        // Update timestamp every second
        setInterval(function() {
            document.getElementById('datetime').textContent = new Date().toLocaleString();
        }, 1000);
    </script>
</body>
</html>
EOF

# Configure Nginx default site
cat > /etc/nginx/sites-available/default << 'EOF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src 'self' http: https: data: blob: 'unsafe-inline'" always;

    # Hide Nginx version
    server_tokens off;
}
EOF

# Test Nginx configuration and reload
nginx -t
systemctl reload nginx

# Configure SSH security (same as bastion for consistency)
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# Restart SSH service
systemctl restart sshd

# Create web server status script
cat > /usr/local/bin/web-status << 'EOF'
#!/bin/bash
echo "=== Web Server Status Check ==="
echo "Hostname: $(hostname)"
echo "System Time: $(date)"
echo "Nginx Status: $(systemctl is-active nginx)"
echo "System Load: $(uptime)"
echo "Memory Usage: $(free -h)"
echo "Disk Usage: $(df -h /)"
echo "Network Connections: $(ss -tuln | wc -l) connections"
echo "Web Requests (last 100): $(tail -100 /var/log/nginx/access.log | wc -l)"
echo "================================="
EOF

chmod +x /usr/local/bin/web-status

# Create log directory for web server monitoring
mkdir -p /var/log/webserver
chown www-data:www-data /var/log/webserver

# Log initialization completion
echo "$(date): Web server initialization completed" >> /var/log/webserver/init.log

echo "Web server initialization completed successfully"