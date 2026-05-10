#!/bin/bash
# =============================================================================
# CHOICE APP - SSL Certificate Setup (Let's Encrypt)
# =============================================================================

set -e

echo "================================================================"
echo "  CHOICE APP - SSL Setup with Let's Encrypt"
echo "================================================================"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root or with sudo"
    exit 1
fi

# Get domain
read -p "Enter your domain (e.g., app.yourdomain.com): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ Domain is required"
    exit 1
fi

echo "➤ Obtaining SSL certificate for $DOMAIN..."

certbot certonly --standalone -d "$DOMAIN" --agree-tos --non-interactive --email admin@$DOMAIN || {
    echo "❌ Failed to obtain certificate"
    exit 1
}

# Copy certificates to nginx directory
mkdir -p /opt/choice-app/nginx/ssl
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /opt/choice-app/nginx/ssl/cert.pem
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /opt/choice-app/nginx/ssl/key.pem

# Set up auto-renewal hook
echo "➤ Setting up auto-renewal..."
mkdir -p /etc/letsencrypt/renewal-hooks/deploy
cat > /etc/letsencrypt/renewal-hooks/deploy/choice-app.sh << EOF
#!/bin/bash
cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem /opt/choice-app/nginx/ssl/cert.pem
cp /etc/letsencrypt/live/$DOMAIN/privkey.pem /opt/choice-app/nginx/ssl/key.pem
docker restart choice_nginx
EOF
chmod +x /etc/letsencrypt/renewal-hooks/deploy/choice-app.sh

echo "➤ Testing certificate renewal..."
certbot renew --dry-run

echo ""
echo "================================================================"
echo "  SSL Setup Complete!"
echo "================================================================"
echo ""
echo "Certificates installed to: /opt/choice-app/nginx/ssl/"
echo "Auto-renewal: Enabled"
echo ""
echo "Next steps:"
echo "  1. Uncomment HTTPS section in nginx/nginx.conf"
echo "  2. Update API_HOST in .env to use https://$DOMAIN"
echo "  3. Rebuild and restart: ./scripts/deploy.sh"
echo ""
