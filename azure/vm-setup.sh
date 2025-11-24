#!/bin/bash

# Azure VM Setup Script
# Run this script on a fresh Ubuntu 22.04 VM to set up the application

set -e

echo "🚀 Starting application setup on Azure VM..."

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
echo "🐳 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Install Nginx
echo "🌐 Installing Nginx..."
sudo apt install -y nginx

# Install Certbot for SSL
echo "🔐 Installing Certbot..."
sudo apt install -y certbot python3-certbot-nginx

# Install Git
echo "📁 Installing Git..."
sudo apt install -y git

# Create application directory
echo "📁 Setting up application directory..."
sudo mkdir -p /opt/configpad
sudo chown $USER:$USER /opt/configpad

echo "✅ Basic setup complete!"
echo ""
echo "Next steps:"
echo "1. Logout and login again for Docker group to take effect"
echo "2. Clone your repository to /opt/configpad"
echo "3. Configure environment variables in .env files"
echo "4. Run 'docker-compose up -d' to start the application"
echo "5. Configure Nginx reverse proxy (see /app/azure/nginx-config.conf)"
echo "6. Run 'sudo certbot --nginx -d app.configpad.com' for SSL"
