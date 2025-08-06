#!/bin/bash

# HomeLab Docker Compose Deployment Script
# Run this script from the applications/docker-compose directory

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
check_directory() {
    if [[ ! -f "docker-compose.yml" ]]; then
        log_error "docker-compose.yml not found. Are you in the applications/docker-compose directory?"
        exit 1
    fi
}

# Check if .env file exists
check_env_file() {
    if [[ ! -f ".env" ]]; then
        log_warning ".env file not found. Creating from template..."
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            log_warning "Please edit .env file with your secure passwords before continuing"
            read -p "Press Enter to continue after editing .env file..."
        else
            log_error ".env.example file not found. Please create .env file manually"
            exit 1
        fi
    fi
}

# Create required directories
create_directories() {
    log_info "Creating required directories..."
    
    directories=(
        "caddy"
        "monitoring/prometheus"
        "monitoring/grafana/provisioning/dashboards"
        "monitoring/grafana/provisioning/datasources"
        "mailserver/config"
        "logs"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        log_info "Created directory: $dir"
    done
}

# Generate secure passwords if needed
generate_passwords() {
    log_info "Checking environment variables..."
    
    # Source .env file
    source .env
    
    # Check if passwords are set to default values
    if [[ "${VAULTWARDEN_ADMIN_TOKEN:-}" == *"your_secure"* ]] || [[ -z "${VAULTWARDEN_ADMIN_TOKEN:-}" ]]; then
        log_warning "Generating secure passwords..."
        
        # Generate new passwords
        VAULTWARDEN_DB_PASSWORD=$(openssl rand -base64 32)
        NEXTCLOUD_DB_PASSWORD=$(openssl rand -base64 32)
        VAULTWARDEN_ADMIN_TOKEN=$(openssl rand -base64 32)
        NEXTCLOUD_ADMIN_PASSWORD=$(openssl rand -base64 16)
        GRAFANA_ADMIN_PASSWORD=$(openssl rand -base64 16)
        MAIL_ADMIN_PASSWORD=$(openssl rand -base64 16)
        
        # Update .env file
        cat > .env << EOF
# HomeLab Environment Variables - Generated $(date)

# Database Passwords
VAULTWARDEN_DB_PASSWORD=${VAULTWARDEN_DB_PASSWORD}
NEXTCLOUD_DB_PASSWORD=${NEXTCLOUD_DB_PASSWORD}

# Application Admin Passwords
VAULTWARDEN_ADMIN_TOKEN=${VAULTWARDEN_ADMIN_TOKEN}
NEXTCLOUD_ADMIN_PASSWORD=${NEXTCLOUD_ADMIN_PASSWORD}
GRAFANA_ADMIN_PASSWORD=${GRAFANA_ADMIN_PASSWORD}

# Mail Configuration
MAIL_ADMIN_PASSWORD=${MAIL_ADMIN_PASSWORD}
EOF
        
        log_success "Generated new secure passwords in .env file"
        log_warning "IMPORTANT: Save these passwords securely!"
        echo
        echo "Admin Passwords:"
        echo "=================="
        echo "Nextcloud Admin: admin / ${NEXTCLOUD_ADMIN_PASSWORD}"
        echo "Grafana Admin: admin / ${GRAFANA_ADMIN_PASSWORD}"
        echo "Mail Admin: admin@avigdol.com / ${MAIL_ADMIN_PASSWORD}"
        echo "Vaultwarden Admin Token: ${VAULTWARDEN_ADMIN_TOKEN}"
        echo
        read -p "Press Enter to continue after saving these passwords..."
    fi
}

# Setup Grafana provisioning
setup_grafana() {
    log_info "Setting up Grafana provisioning..."
    
    # Create datasources
    cat > monitoring/grafana/provisioning/datasources/prometheus.yml << 'EOF'
apiVersion: 1

datasources:
  - name: Prometheus
    type: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: true
EOF

    # Create dashboard provider
    cat > monitoring/grafana/provisioning/dashboards/dashboard.yml << 'EOF'
apiVersion: 1

providers:
  - name: 'homelab'
    orgId: 1
    folder: 'HomeLab'
    type: file
    disableDeletion: false
    editable: true
    updateIntervalSeconds: 10
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards
EOF

    log_success "Grafana provisioning configured"
}

# Setup mailserver basic config
setup_mailserver() {
    log_info "Setting up mailserver configuration..."
    
    # Create basic postfix configuration
    mkdir -p mailserver/config
    
    # Create accounts file
    echo "admin@avigdol.com|{SHA512-CRYPT}\$6\$salt\$hash" > mailserver/config/postfix-accounts.cf
    
    log_warning "Mailserver requires additional configuration after deployment"
    log_info "Run: docker exec -it homelab-mailserver setup email add admin@avigdol.com [password]"
}

# Check system resources
check_system_resources() {
    log_info "Checking system resources..."
    
    # Check available memory
    available_memory=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    if [[ $available_memory -lt 500 ]]; then
        log_warning "Low available memory: ${available_memory}MB. Consider stopping some services."
    fi
    
    # Check disk space
    available_disk=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')
    if [[ $available_disk -lt 5 ]]; then
        log_warning "Low disk space: ${available_disk}GB available"
    fi
    
    log_success "System resources check completed"
}

# Deploy services
deploy_services() {
    log_info "Deploying HomeLab services..."
    
    # Pull images first
    log_info "Pulling Docker images..."
    docker compose pull
    
    # Start core services first (databases, caddy)
    log_info "Starting core services..."
    docker compose up -d caddy vaultwarden-db nextcloud-db
    
    # Wait for databases to be ready
    log_info "Waiting for databases to be ready..."
    sleep 30
    
    # Start application services
    log_info "Starting application services..."
    docker compose up -d vaultwarden nextcloud
    
    # Wait for applications to be ready
    sleep 30
    
    # Start monitoring services
    log_info "Starting monitoring services..."
    docker compose up -d prometheus grafana node-exporter cadvisor
    
    # Start Jenkins
    log_info "Starting Jenkins..."
    docker compose up -d jenkins
    
    # Start mailserver last (requires more setup)
    log_info "Starting mailserver..."
    docker compose up -d mailserver
    
    log_success "All services deployed!"
}

# Check service health
check_services() {
    log_info "Checking service health..."
    
    services=(
        "homelab-caddy"
        "homelab-vaultwarden"
        "homelab-nextcloud"
        "homelab-prometheus"
        "homelab-grafana"
        "homelab-jenkins"
    )
    
    for service in "${services[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "$service"; then
            log_success "$service is running"
        else
            log_error "$service is not running"
        fi
    done
}

# Show access information
show_access_info() {
    log_success "Deployment completed!"
    echo
    echo "Service Access URLs:"
    echo "==================="
    echo "🔐 Vaultwarden: https://passwords.avigdol.com"
    echo "📁 Nextcloud: https://files.avigdol.com"
    echo "📊 Grafana: https://monitor.avigdol.com"
    echo "🔧 Jenkins: https://jenkins.avigdol.com"
    echo "📧 Mail: Use IMAP/SMTP settings with mail.avigdol.com"
    echo
    echo "Local Access (for troubleshooting):"
    echo "===================================="
    echo "🔍 Caddy Admin: http://localhost:2019"
    echo "📊 Prometheus: http://localhost:9090 (via caddy proxy)"
    echo
    echo "Next Steps:"
    echo "==========="
    echo "1. Wait 5-10 minutes for all services to fully start"
    echo "2. Check DNS records point to this server"
    echo "3. Configure mailserver: docker exec -it homelab-mailserver setup email add admin@avigdol.com"
    echo "4. Access services and complete initial setup"
    echo "5. Configure monitoring dashboards in Grafana"
    echo
    echo "Troubleshooting:"
    echo "================"
    echo "• Check logs: docker compose logs -f [service]"
    echo "• Check status: docker compose ps"
    echo "• Restart service: docker compose restart [service]"
}

# Cleanup function
cleanup() {
    log_warning "Stopping all services..."
    docker compose down
}

# Trap cleanup on script exit
trap cleanup EXIT

# Main execution
main() {
    log_info "Starting HomeLab deployment..."
    
    check_directory
    check_env_file
    generate_passwords
    create_directories
    setup_grafana
    setup_mailserver
    check_system_resources
    deploy_services
    
    # Wait for services to stabilize
    log_info "Waiting for services to stabilize..."
    sleep 60
    
    check_services
    show_access_info
    
    # Remove cleanup trap since we want services to keep running
    trap - EXIT
}

# Script options
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "stop")
        log_info "Stopping all services..."
        docker compose down
        ;;
    "restart")
        log_info "Restarting all services..."
        docker compose restart
        ;;
    "logs")
        docker compose logs -f "${2:-}"
        ;;
    "status")
        docker compose ps
        ;;
    "clean")
        log_warning "This will remove all data! Continue? (y/N)"
        read -r response
        if [[ "$response" =~ ^[Yy]$ ]]; then
            log_warning "Removing all containers and volumes..."
            docker compose down -v --remove-orphans
            docker system prune -f
            log_success "Cleanup completed"
        else
            log_info "Cleanup cancelled"
        fi
        ;;
    "update")
        log_info "Updating all services..."
        docker compose pull
        docker compose up -d
        ;;
    "backup")
        log_info "Creating backup..."
        mkdir -p backups/$(date +%Y%m%d_%H%M%S)
        docker compose exec -T vaultwarden-db pg_dump -U vaultwarden vaultwarden > backups/$(date +%Y%m%d_%H%M%S)/vaultwarden.sql
        docker compose exec -T nextcloud-db pg_dump -U nextcloud nextcloud > backups/$(date +%Y%m%d_%H%M%S)/nextcloud.sql
        tar -czf backups/$(date +%Y%m%d_%H%M%S)/volumes.tar.gz -C /var/lib/docker/volumes .
        log_success "Backup completed in backups/$(date +%Y%m%d_%H%M%S)/"
        ;;
    "help")
        echo "HomeLab Deployment Script"
        echo "Usage: $0 [command]"
        echo
        echo "Commands:"
        echo "  deploy   - Deploy all services (default)"
        echo "  stop     - Stop all services"
        echo "  restart  - Restart all services"
        echo "  logs     - Show logs for all services or specific service"
        echo "  status   - Show status of all services"
        echo "  clean    - Remove all containers and volumes (destructive)"
        echo "  update   - Update all service images"
        echo "  backup   - Create backup of databases and volumes"
        echo "  help     - Show this help message"
        echo
        echo "Examples:"
        echo "  $0 deploy          # Deploy all services"
        echo "  $0 logs caddy      # Show Caddy logs"
        echo "  $0 logs            # Show all logs"
        ;;
    *)
        log_error "Unknown command: $1"
        echo "Use '$0 help' for usage information"
        exit 1
        ;;

    # Add this near the end of the deploy_services() function:
    log_info "Setting up smart backup/restore..."
    if command -v smart-backup &> /dev/null; then
        smart-backup auto
    else
        log_warning "Smart backup script not found, skipping..."
    fi
esac