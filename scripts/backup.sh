#!/bin/bash
set -e

# HomeLab Backup Script
echo "Starting HomeLab backup..."

# Get instance information
INSTANCE_ID=$(terraform output -raw instance_id 2>/dev/null || echo "unknown")
BUCKET_NAME=$(terraform output -raw s3_bucket_name 2>/dev/null || echo "homelab-backups")
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup directory
BACKUP_DIR="/tmp/homelab_backup_${DATE}"
mkdir -p ${BACKUP_DIR}

echo "Backing up Docker volumes..."
# This would run on the EC2 instance
# For now, just create a placeholder
echo "Backup script ready - run this on your EC2 instance"

echo "Backup completed: ${BACKUP_DIR}"
