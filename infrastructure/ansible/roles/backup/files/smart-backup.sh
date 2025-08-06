#!/bin/bash
# Smart Backup/Restore System - Fixed S3 paths
# infrastructure/ansible/roles/backup/files/smart-backup.sh

set -euo pipefail

# Colors and configuration
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

S3_BUCKET="${S3_BUCKET_NAME:-homelab-backups-874888505976}"
BACKUP_PREFIX="backups"  # Fixed: no double prefix
DEPLOYMENT_MODE="${DEPLOYMENT_MODE:-auto}"

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if backups exist in S3
check_existing_backups() {
    log_info "Checking for existing backups in S3..."
    
    local latest_backup
    latest_backup=$(aws s3 ls "s3://$S3_BUCKET/$BACKUP_PREFIX/" --recursive \
        | sort | tail -n 1 | awk '{print $4}' || echo "")
    
    if [ -n "$latest_backup" ]; then
        echo "$latest_backup"
        return 0
    else
        return 1
    fi
}

# Get backup metadata
get_backup_info() {
    local backup_path="$1"
    
    # Try to get backup metadata
    local metadata_file="${backup_path%/*}/metadata.json"
    
    if aws s3 ls "s3://$S3_BUCKET/$metadata_file" &>/dev/null; then
        aws s3 cp "s3://$S3_BUCKET/$metadata_file" - 2>/dev/null || echo "{}"
    else
        echo "{}"
    fi
}

# Create backup metadata
create_backup_metadata() {
    local backup_path="$1"
    local backup_type="$2"
    
    cat > /tmp/backup-metadata.json << EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "backup_path": "$backup_path",
  "backup_type": "$backup_type",
  "instance_id": "$(curl -s http://169.254.169.254/latest/meta-data/instance-id || echo unknown)",
  "rds_endpoint": "${RDS_ENDPOINT:-unknown}",
  "applications": ["vaultwarden", "nextcloud", "grafana", "jenkins"],
  "version": "1.0"
}
EOF
    
    aws s3 cp /tmp/backup-metadata.json "s3://$S3_BUCKET/${backup_path%/*}/metadata.json"
    rm -f /tmp/backup-metadata.json
}

# Restore databases from backup
restore_databases() {
    local backup_path="$1"
    
    log_info "Restoring databases from backup: $backup_path"
    
    local apps=("vaultwarden" "nextcloud" "grafana" "jenkins")
    local restore_dir="/tmp/restore-$(date +%s)"
    mkdir -p "$restore_dir"
    
    # Download and extract backup
    aws s3 cp "s3://$S3_BUCKET/$backup_path" "$restore_dir/backup.tar.gz"
    tar -xzf "$restore_dir/backup.tar.gz" -C "$restore_dir"
    
    for app in "${apps[@]}"; do
        log_info "Restoring $app database..."
        
        # Find the database backup file
        local db_backup
        db_backup=$(find "$restore_dir" -name "${app}_*.sql.gz" | head -n 1)
        
        if [ -z "$db_backup" ]; then
            log_warning "No backup found for $app database, skipping..."
            continue
        fi
        
        # Get current database credentials
        local secret_json
        if ! secret_json=$(aws secretsmanager get-secret-value \
            --secret-id "homelab-dev-${app}-db" \
            --query SecretString --output text 2>/dev/null); then
            log_error "Could not retrieve credentials for $app"
            continue
        fi
        
        # Parse credentials
        local db_host db_port db_name db_user db_password
        db_host=$(echo "$secret_json" | jq -r '.host')
        db_port=$(echo "$secret_json" | jq -r '.port')
        db_name=$(echo "$secret_json" | jq -r '.database')
        db_user=$(echo "$secret_json" | jq -r '.username')
        db_password=$(echo "$secret_json" | jq -r '.password')
        
        # Restore database
        if gunzip -c "$db_backup" | PGPASSWORD="$db_password" psql \
            -h "$db_host" \
            -p "$db_port" \
            -U "$db_user" \
            -d "$db_name" \
            --quiet; then
            
            log_success "$app database restored successfully"
        else
            log_error "Failed to restore $app database"
        fi
    done
    
    # Cleanup
    rm -rf "$restore_dir"
}

# Restore Docker volumes
restore_volumes() {
    local backup_path="$1"
    
    log_info "Restoring Docker volumes from backup..."
    
    local restore_dir="/tmp/restore-volumes-$(date +%s)"
    mkdir -p "$restore_dir"
    
    # Download backup
    aws s3 cp "s3://$S3_BUCKET/$backup_path" "$restore_dir/backup.tar.gz"
    
    # Extract and restore volumes
    tar -xzf "$restore_dir/backup.tar.gz" -C "$restore_dir"
    
    # Find volume backups
    find "$restore_dir" -name "*.tar.gz" -path "*/volumes/*" | while read -r volume_backup; do
        local volume_name
        volume_name=$(basename "$volume_backup" .tar.gz | sed 's/_[0-9]*_[0-9]*$//')
        
        log_info "Restoring volume: $volume_name"
        
        # Create volume if it doesn't exist
        docker volume create "$volume_name" || true
        
        # Restore volume content
        docker run --rm \
            -v "$volume_name:/restore-dest" \
            -v "$restore_dir:/backup-source:ro" \
            busybox \
            tar -xzf "/backup-source/$(basename "$volume_backup")" -C /restore-dest
            
        log_success "Volume $volume_name restored"
    done
    
    rm -rf "$restore_dir"
}

# Create full backup
create_backup() {
    log_info "Creating comprehensive backup..."
    
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="homelab-backup_${timestamp}"
    local backup_dir="/tmp/$backup_name"
    
    mkdir -p "$backup_dir"/{databases,volumes,configs}
    
    # Backup databases
    log_info "Backing up databases..."
    local apps=("vaultwarden" "nextcloud" "grafana" "jenkins")
    
    for app in "${apps[@]}"; do
        log_info "Backing up $app database..."
        
        local secret_json
        if ! secret_json=$(aws secretsmanager get-secret-value \
            --secret-id "homelab-dev-${app}-db" \
            --query SecretString --output text 2>/dev/null); then
            log_warning "Could not retrieve credentials for $app, skipping..."
            continue
        fi
        
        local db_host db_port db_name db_user db_password
        db_host=$(echo "$secret_json" | jq -r '.host')
        db_port=$(echo "$secret_json" | jq -r '.port')
        db_name=$(echo "$secret_json" | jq -r '.database')
        db_user=$(echo "$secret_json" | jq -r '.username')
        db_password=$(echo "$secret_json" | jq -r '.password')
        
        PGPASSWORD="$db_password" pg_dump \
            -h "$db_host" -p "$db_port" -U "$db_user" -d "$db_name" \
            --no-password --verbose --clean --if-exists | \
            gzip > "$backup_dir/databases/${app}_${timestamp}.sql.gz"
            
        log_success "$app database backed up"
    done
    
    # Backup volumes (if Docker is running)
    if command -v docker &> /dev/null && docker info &> /dev/null; then
        log_info "Backing up Docker volumes..."
        docker volume ls --format "{{.Name}}" | grep -E "(homelab|vaultwarden|nextcloud|grafana|jenkins)" | while read -r volume; do
            if [ -n "$volume" ]; then
                log_info "Backing up volume: $volume"
                docker run --rm \
                    -v "$volume:/backup-source:ro" \
                    -v "$backup_dir/volumes:/backup-dest" \
                    busybox \
                    tar -czf "/backup-dest/${volume}_${timestamp}.tar.gz" -C /backup-source .
            fi
        done
    else
        log_warning "Docker not running, skipping volume backup"
    fi
    
    # Backup configurations
    log_info "Backing up configurations..."
    if [ -d "/home/ubuntu/homelab" ]; then
        tar -czf "$backup_dir/configs/homelab_${timestamp}.tar.gz" -C /home/ubuntu homelab
    fi
    
    # Create backup archive
    log_info "Creating backup archive..."
    tar -czf "/tmp/${backup_name}.tar.gz" -C "/tmp" "$backup_name"
    
    # Upload to S3 with fixed path
    local s3_path="$BACKUP_PREFIX/$(date +%Y)/$(date +%m)/${backup_name}.tar.gz"
    aws s3 cp "/tmp/${backup_name}.tar.gz" "s3://$S3_BUCKET/$s3_path"
    
    # Create metadata
    create_backup_metadata "$s3_path" "full"
    
    # Cleanup
    rm -rf "$backup_dir" "/tmp/${backup_name}.tar.gz"
    
    log_success "Backup completed: s3://$S3_BUCKET/$s3_path"
    echo "$s3_path"
}

# Main function
main() {
    local action="${1:-auto}"
    
    case "$action" in
        "auto")
            log_info "🚀 Smart Backup/Restore - Auto Mode"
            
            # Check for existing backups
            if latest_backup=$(check_existing_backups); then
                log_info "Found existing backup: $latest_backup"
                
                # Get backup info
                local backup_info
                backup_info=$(get_backup_info "$latest_backup")
                local backup_age
                backup_age=$(echo "$backup_info" | jq -r '.timestamp // "1970-01-01T00:00:00Z"')
                
                # Calculate age in days
                local age_seconds
                age_seconds=$(( $(date +%s) - $(date -d "$backup_age" +%s 2>/dev/null || echo 0) ))
                local age_days=$(( age_seconds / 86400 ))
                
                log_info "Backup age: $age_days days"
                
                if [ "$age_days" -lt 30 ] && [ "$DEPLOYMENT_MODE" != "fresh" ]; then
                    log_info "🔄 Restoring from recent backup..."
                    restore_databases "$latest_backup"
                    restore_volumes "$latest_backup"
                    log_success "✅ Restore completed!"
                else
                    log_info "🗂️ Backup too old or fresh deployment requested"
                    log_info "🏗️ Deploying fresh, then creating backup..."
                    sleep 5  # Give services time to start
                    create_backup
                fi
            else
                log_info "📦 No existing backups found"
                log_info "🏗️ Will create initial backup after deployment..."
                sleep 10  # Give services time to start and initialize
                create_backup
            fi
            ;;
        "backup")
            create_backup
            ;;
        "restore")
            if latest_backup=$(check_existing_backups); then
                restore_databases "$latest_backup"
                restore_volumes "$latest_backup"
            else
                log_error "No backups found to restore from"
                exit 1
            fi
            ;;
        "list")
            log_info "Available backups:"
            aws s3 ls "s3://$S3_BUCKET/$BACKUP_PREFIX/" --recursive | sort -k1,2
            ;;
        *)
            echo "Usage: $0 {auto|backup|restore|list}"
            echo "  auto    - Smart backup/restore based on existing backups"
            echo "  backup  - Force create new backup"
            echo "  restore - Force restore from latest backup"
            echo "  list    - List available backups"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"