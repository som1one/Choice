#!/bin/bash
# =============================================================================
# CHOICE APP - Server Initialization Script
# Run this on a fresh Ubuntu server to prepare it for deployment
# =============================================================================

set -e

echo "================================================================"
echo "  CHOICE APP - Server Initialization"
echo "================================================================"
echo ""

# Configuration
DOCKER_COMPOSE_VERSION="2.23.0"

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root or with sudo"
    exit 1
fi

echo "➤ Updating system packages..."
apt-get update && apt-get upgrade -y

echo "➤ Installing essential packages..."
apt-get install -y \
    curl \
    wget \
    git \
    nano \
    htop \
    ufw \
    fail2ban \
    certbot \
    python3-certbot-nginx \
    nginx \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release

echo "➤ Installing Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo "✓ Docker installed"
else
    echo "✓ Docker already installed"
fi

echo "➤ Installing Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose
    echo "✓ Docker Compose installed"
else
    echo "✓ Docker Compose already installed"
fi

echo "➤ Adding user to docker group..."
read -p "Enter your username (default: ubuntu): " USERNAME
USERNAME=${USERNAME:-ubuntu}
usermod -aG docker $USERNAME

echo "➤ Configuring firewall (UFW)..."
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw allow 8001:8008/tcp  # API ports (direct access if needed)
ufw --force enable

echo "➤ Configuring fail2ban..."
systemctl enable fail2ban
systemctl start fail2ban

echo "➤ Creating application directory..."
mkdir -p /opt/choice-app
cd /opt/choice-app

echo "➤ Setting up swap (2GB)..."
if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "✓ Swap created"
else
    echo "✓ Swap already exists"
fi

echo ""
echo "================================================================"
echo "  Server initialization complete!"
echo "================================================================"
echo ""
echo "Next steps:"
echo "  1. Log out and log back in for Docker permissions to take effect"
echo "  2. Clone your repository: git clone <your-repo> /opt/choice-app"
echo "  3. Copy .env.example to .env and configure it"
echo "  4. Run: ./scripts/deploy.sh"
echo ""
echo "Optional - Configure SSL with Let's Encrypt:"
echo "  certbot --nginx -d your-domain.com"
echo ""
