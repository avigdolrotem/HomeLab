#!/bin/bash
# applications/docker-compose/generate-secrets.sh
# Generate application secrets and .env file

set -e

ENV_FILE=".env"
ENV_DIR=".env.d"

echo "🔐 Generating application secrets..."

# Function to generate random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-25
}

# Create .env file with generated secrets
cat > "$ENV_FILE" << EOF
# HomeLab Application Secrets
# Generated on: $(date)

# Nextcloud Admin Password
NEXTCLOUD_ADMIN_PASS=$(generate_password)

# Grafana Admin Password  
GRAFANA_ADMIN_PASS=$(generate_password)

# Redis Password
REDIS_PASSWORD=$(generate_password)

# S3 Bucket Name (from AWS deployment)
S3_BUCKET_NAME=${S3_BUCKET_NAME:-homelab-backups-default}

# Additional application secrets
JWT_SECRET=$(generate_password)
APP_KEY=$(openssl rand -base64 32)

EOF

# Set proper permissions
chmod 600 "$ENV_FILE"

# Verify database environment files exist
if [ ! -d "$ENV_DIR" ] || [ -z "$(ls -A $ENV_DIR 2>/dev/null)" ]; then
    echo "⚠️  Warning: Database environment files not found in $ENV_DIR"
    echo "   Make sure to run: /usr/local/bin/generate-db-env"
    echo "   This should be done automatically by Ansible"
fi

echo "✅ Application secrets generated in $ENV_FILE"
echo "✅ Environment files in $ENV_DIR ready for Docker Compose"
echo ""
echo "🔍 Generated secrets:"
echo "   • Nextcloud admin password"
echo "   • Grafana admin password" 
echo "   • Redis password"
echo "   • JWT secret"
echo "   • Application key"
echo ""
echo "⚡ Database credentials are loaded from Secrets Manager via $ENV_DIR/*.env files"