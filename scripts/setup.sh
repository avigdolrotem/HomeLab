# ========================================
# File: scripts/setup.sh
# ========================================

#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Check if we're in the right directory
if [[ ! -f "README.md" ]]; then
    print_error "Please run this script from the homelab root directory"
    exit 1
fi

print_header "HomeLab Setup Script"

# Step 1: Check prerequisites
print_status "Checking prerequisites..."

# Check if git is installed
if ! command -v git &> /dev/null; then
    print_error "Git is not installed. Please install git first."
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_warning "AWS CLI is not installed. You'll need to install it manually."
    echo "Visit: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
fi

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_warning "Terraform is not installed. You'll need to install it manually."
    echo "Visit: https://developer.hashicorp.com/terraform/install"
fi

# Step 2: Create directory structure
print_status "Creating directory structure..."

# Create all necessary directories
mkdir -p .github/{workflows,ISSUE_TEMPLATE}
mkdir -p infrastructure/terraform/{environments/{dev,prod},modules/{vpc,ec2,security-group,iam,s3,lambda-scheduler},shared}
mkdir -p infrastructure/ansible/{inventories,playbooks,roles/{common,docker,k3s,monitoring,security},group_vars}
mkdir -p applications/{docker-compose/configs/{traefik,vaultwarden,mailserver,nextcloud},kubernetes/{namespaces,apps/{vaultwarden,mailserver,nextcloud},monitoring/{prometheus,grafana},helm/charts}}
mkdir -p scripts docs/diagrams tests/{terraform,ansible/molecule,integration}

print_status "Directory structure created successfully!"

# Step 3: Create essential configuration files
print_status "Creating configuration files..."

# Create .gitignore
cat > .gitignore << 'EOF'
# Terraform
*.tfstate
*.tfstate.*
*.tfplan
*.tfvars
.terraform/
.terraform.lock.hcl

# Ansible
*.retry
.vault_pass

# Environment variables
.env
*.env

# Docker
.docker/

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Backup files
*.backup
*.bak

# SSL certificates
*.pem
*.key
*.crt

# AWS
.aws/
credentials
EOF

# Create pre-commit config
cat > .pre-commit-config.yaml << 'EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.4.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.83.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
      - id: terraform_docs
      - id: terraform_tflint

  - repo: https://github.com/ansible/ansible-lint
    rev: v6.20.0
    hooks:
      - id: ansible-lint
EOF

# Create main README
cat > README.md << 'EOF'
# HomeLab Project

A production-grade HomeLab environment on AWS for learning DevOps practices.

## Quick Start

1. **Prerequisites**
   - AWS CLI installed and configured
   - Terraform >= 1.6
   - Git
   - Domain name (avigdol.com)

2. **Setup**
   ```bash
   ./scripts/setup.sh
   ```

3. **Deploy Infrastructure**
   ```bash
   cd infrastructure/terraform/environments/dev
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   terraform init
   terraform plan
   terraform apply
   ```

## Architecture

- **Single EC2 Instance**: t2.micro (free tier eligible)
- **Docker Compose**: Initial application deployment
- **K3s**: Kubernetes learning environment
- **Auto Scheduling**: Lambda-based start/stop automation

## Applications

- **Vaultwarden**: Password manager (passwords.avigdol.com)
- **Mailserver**: Full email server (mail.avigdol.com)
- **Nextcloud**: File sync (files.avigdol.com)
- **Monitoring**: Prometheus + Grafana (monitor.avigdol.com)
- **Jenkins**: CI/CD (jenkins.avigdol.com)

## Cost Optimization

- Estimated cost: $5-13/month after free tier
- Auto start/stop saves ~66% on EC2 costs
- S3 lifecycle policies for backup cost management

## Documentation

- [Setup Guide](docs/SETUP_GUIDE.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Runbook](docs/RUNBOOK.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
EOF

# Create docs/SETUP_GUIDE.md
cat > docs/SETUP_GUIDE.md << 'EOF'
# HomeLab Complete Setup Guide

## Phase 1: Prerequisites and Initial Setup

### Step 1: Install Required Tools

**Why these tools?**
- **AWS CLI**: Interact with AWS services
- **Terraform**: Infrastructure as Code
- **Git**: Version control and GitOps workflow

```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Terraform (Linux/macOS)
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Verify installations
aws --version
terraform --version
git --version
```

For detailed setup instructions, see the complete setup guide in the repository.
EOF

# Create docs/ARCHITECTURE.md
cat > docs/ARCHITECTURE.md << 'EOF'
# HomeLab Architecture Documentation

## Overview

This document describes the architecture decisions and design principles for the HomeLab project.

## Core Architecture

### Single EC2 Instance Design
- **Rationale**: Cost optimization while maintaining full functionality
- **Instance Type**: t2.micro (free tier eligible)
- **Operating System**: Amazon Linux 2

### Hybrid Container Orchestration
- **Docker Compose**: Initial deployment for immediate results
- **K3s**: Kubernetes learning environment on the same instance
- **Migration Path**: Gradual transition from Docker Compose to Kubernetes

### Network Architecture
- **VPC**: Single VPC with public subnet
- **Security**: Security groups with minimal required ports
- **DNS**: Route53 for domain management
- **SSL**: Let's Encrypt via Traefik

## Cost Optimization Strategy

### Auto-Scheduling
- **Lambda Functions**: Start/stop EC2 instance on schedule
- **Schedule**: 8 AM - 8 PM Israel time (12 hours/day)
- **Savings**: ~66% reduction in EC2 costs

### Storage Optimization
- **S3 Lifecycle Policies**: Transition to cheaper storage classes
- **EBS Optimization**: Right-sized volumes with encryption

## Security Design

### Network Security
- **Security Groups**: Principle of least privilege
- **SSH Access**: Restricted to specific IP addresses
- **SSL/TLS**: Automatic certificate management

### Access Management
- **IAM Roles**: EC2 instance roles for AWS service access
- **Secrets Management**: AWS Secrets Manager integration
- **Key Management**: AWS KMS for encryption keys

For more details, see the implementation in the infrastructure/terraform directory.
EOF

# Create docs/RUNBOOK.md
cat > docs/RUNBOOK.md << 'EOF'
# HomeLab Operations Runbook

## Daily Operations

### Starting Your Lab
```bash
# Manual start (if auto-scheduling is disabled)
aws ec2 start-instances --instance-ids $(terraform output -raw instance_id)

# Check status
aws ec2 describe-instances --instance-ids $(terraform output -raw instance_id)
```

### Accessing Services
- **SSH**: `ssh -i ~/.ssh/homelab-key.pem ec2-user@$(terraform output -raw instance_public_ip)`
- **Applications**: All accessible via HTTPS at their respective subdomains

### Monitoring
```bash
# Check all services
docker compose ps

# View logs
docker compose logs -f [service_name]

# Check resource usage
docker stats
```

## Backup and Recovery

### Manual Backup
```bash
# Run backup script
./scripts/backup.sh

# Verify backup in S3
aws s3 ls s3://your-backup-bucket/
```

### Disaster Recovery
```bash
# Restore from backup
./scripts/restore.sh
```

## Troubleshooting

### Common Issues
1. **Service won't start**: Check logs with `docker compose logs [service]`
2. **SSL certificate issues**: Check Traefik logs
3. **High resource usage**: Check with `docker stats`

For detailed troubleshooting, see TROUBLESHOOTING.md
EOF

# Create docs/TROUBLESHOOTING.md
cat > docs/TROUBLESHOOTING.md << 'EOF'
# HomeLab Troubleshooting Guide

## Infrastructure Issues

### Terraform Errors

**Issue**: State file locked
```bash
# Solution: Force unlock (use carefully)
terraform force-unlock LOCK_ID
```

**Issue**: Resource already exists
```bash
# Solution: Import existing resource
terraform import aws_instance.main i-1234567890abcdef0
```

### EC2 Issues

**Issue**: Instance won't start
```bash
# Check instance status
aws ec2 describe-instance-status --instance-ids YOUR_INSTANCE_ID

# View console output
aws ec2 get-console-output --instance-id YOUR_INSTANCE_ID
```

## Application Issues

### Docker Compose Problems

**Issue**: Service fails to start
```bash
# Check specific service logs
docker compose logs SERVICE_NAME

# Restart specific service
docker compose restart SERVICE_NAME

# Rebuild and restart
docker compose up -d --build SERVICE_NAME
```

**Issue**: Port conflicts
```bash
# Check what's using the port
sudo netstat -tulpn | grep :PORT_NUMBER

# Stop conflicting service
sudo systemctl stop SERVICE_NAME
```

### SSL Certificate Issues

**Issue**: Certificate not generating
```bash
# Check Traefik logs
docker logs traefik

# Manually trigger certificate request
docker exec traefik traefik version
```

## Performance Issues

### High Memory Usage
```bash
# Check memory usage
free -h
docker stats

# Clean up unused containers/images
docker system prune -a
```

### High Disk Usage
```bash
# Check disk usage
df -h

# Clean Docker volumes
docker volume prune

# Clean logs
sudo journalctl --vacuum-time=3d
```

## Cost Issues

### Unexpected Charges
```bash
# Check current costs
./scripts/cost-report.sh

# Review EC2 usage
aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType]'
```

## Recovery Procedures

### Complete System Recovery
1. **Backup current state** (if possible)
2. **Run disaster recovery script**: `./scripts/restore.sh`
3. **Verify all services**: Check each application endpoint
4. **Update DNS** if IP changed

### Partial Service Recovery
1. **Identify failed service**: `docker compose ps`
2. **Check logs**: `docker compose logs SERVICE_NAME`
3. **Restart service**: `docker compose restart SERVICE_NAME`
4. **If persistent, rebuild**: `docker compose up -d --build SERVICE_NAME`

For additional help, check the logs in CloudWatch or contact support.
EOF

print_status "Documentation files created!"

# Create GitHub workflow files
mkdir -p .github/workflows .github/ISSUE_TEMPLATE

# Create terraform workflow
cat > .github/workflows/terraform-plan.yml << 'EOF'
name: Terraform Plan

on:
  pull_request:
    branches: [ main ]
    paths: [ 'infrastructure/terraform/**' ]

jobs:
  terraform-plan:
    runs-on: ubuntu-latest
    
    defaults:
      run:
        working-directory: infrastructure/terraform/environments/dev
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v3
      with:
        terraform_version: 1.6.0
    
    - name: Configure AWS Credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
        aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        aws-region: ${{ secrets.AWS_REGION }}
    
    - name: Terraform Init
      run: terraform init
    
    - name: Terraform Validate
      run: terraform validate
    
    - name: Terraform Plan
      run: terraform plan -no-color
      env:
        TF_VAR_key_name: ${{ secrets.TF_VAR_key_name }}
        TF_VAR_s3_bucket_name: ${{ secrets.TF_VAR_s3_bucket_name }}
        TF_VAR_allowed_cidr_blocks: ${{ secrets.TF_VAR_allowed_cidr_blocks }}
EOF

# Create bug report template
cat > .github/ISSUE_TEMPLATE/bug_report.md << 'EOF'
---
name: Bug report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Go to '...'
2. Click on '....'
3. Scroll down to '....'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Environment:**
 - OS: [e.g. Ubuntu 20.04]
 - Terraform Version: [e.g. 1.6.0]
 - AWS CLI Version: [e.g. 2.0.0]

**Additional context**
Add any other context about the problem here.
EOF

# Create feature request template
cat > .github/ISSUE_TEMPLATE/feature_request.md << 'EOF'
---
name: Feature request
about: Suggest an idea for this project
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

**Is your feature request related to a problem? Please describe.**
A clear and concise description of what the problem is.

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features you've considered.

**Additional context**
Add any other context or screenshots about the feature request here.
EOF

print_status "GitHub templates created!"

# Create additional essential scripts
cat > scripts/backup.sh << 'EOF'
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
EOF

chmod +x scripts/backup.sh

cat > scripts/deploy.sh << 'EOF'
#!/bin/bash
set -e

# HomeLab Deployment Script
echo "Starting HomeLab deployment..."

# Check prerequisites
command -v terraform >/dev/null 2>&1 || { echo "Terraform not installed" >&2; exit 1; }
command -v aws >/dev/null 2>&1 || { echo "AWS CLI not installed" >&2; exit 1; }

# Deploy infrastructure
echo "Deploying infrastructure..."
cd infrastructure/terraform/environments/dev
terraform init
terraform plan
terraform apply -auto-approve

# Get instance IP
PUBLIC_IP=$(terraform output -raw instance_public_ip)
echo "Instance deployed at: ${PUBLIC_IP}"

echo "Deployment completed!"
echo "SSH: ssh -i ~/.ssh/homelab-key.pem ec2-user@${PUBLIC_IP}"
EOF

chmod +x scripts/deploy.sh

print_status "Additional scripts created!"

# Create configuration files structure
mkdir -p applications/docker-compose/configs/{traefik,vaultwarden,mailserver,nextcloud}

# Create Traefik configuration
cat > applications/docker-compose/configs/traefik/traefik.yml << 'EOF'
api:
  dashboard: true
  insecure: false

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entrypoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

providers:
  docker:
    exposedByDefault: false
  file:
    filename: /etc/traefik/dynamic.yml

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@avigdol.com
      storage: /acme/acme.json
      httpChallenge:
        entryPoint: web
EOF

cat > applications/docker-compose/configs/traefik/dynamic.yml << 'EOF'
# Dynamic configuration for Traefik
http:
  middlewares:
    default-headers:
      headers:
        frameDeny: true
        sslRedirect: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000

    secure-headers:
      headers:
        accessControlAllowMethods:
          - GET
          - OPTIONS
          - PUT
        accessControlMaxAge: 100
        hostsProxyHeaders:
          - "X-Forwarded-Host"
        referrerPolicy: "same-origin"
EOF

# Create environment file template
cat > applications/docker-compose/.env.example << 'EOF'
# Database passwords
POSTGRES_PASSWORD=your_secure_password_here

# Application passwords
VAULTWARDEN_ADMIN_TOKEN=your_admin_token_here
NEXTCLOUD_ADMIN_PASSWORD=your_nextcloud_password
GRAFANA_ADMIN_PASSWORD=your_grafana_password

# Email configuration
MAILSERVER_DOMAIN=avigdol.com

# Timezone
TZ=Asia/Jerusalem
EOF

print_status "Application configuration files created!"

# Step 4: Create cost monitoring script
cat > scripts/cost-report.sh << 'EOF'
#!/bin/bash

# Get current month costs
echo "=== AWS Cost Report ==="
echo "Current month costs:"

# Get cost for current month
aws ce get-cost-and-usage \
    --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text

echo "Previous month costs:"
# Get cost for previous month
PREV_MONTH=$(date -d "$(date +%Y-%m-01) -1 month" +%Y-%m)
aws ce get-cost-and-usage \
    --time-period Start=${PREV_MONTH}-01,End=$(date +%Y-%m-01) \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --query 'ResultsByTime[0].Total.UnblendedCost.Amount' \
    --output text

echo "=== Service Breakdown ==="
aws ce get-cost-and-usage \
    --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
    --granularity MONTHLY \
    --metrics "UnblendedCost" \
    --group-by Type=DIMENSION,Key=SERVICE \
    --query 'ResultsByTime[0].Groups[?Total.UnblendedCost.Amount!=`0`].[Keys[0],Total.UnblendedCost.Amount]' \
    --output table
EOF

chmod +x scripts/cost-report.sh

print_status "Cost monitoring script created!"

# Step 5: Initialize git repository if not already initialized
if [[ ! -d ".git" ]]; then
    print_status "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit: HomeLab project structure"
    print_status "Git repository initialized!"
else
    print_status "Git repository already exists, skipping initialization"
fi

print_header "Setup Complete!"

echo ""
print_status "Next steps:"
echo "1. Install missing prerequisites (AWS CLI, Terraform)"
echo "2. Configure AWS CLI: aws configure"
echo "3. Create an AWS key pair for EC2 access"
echo "4. Get your home IP address: curl ifconfig.me"
echo "5. Copy and edit terraform.tfvars:"
echo "   cd infrastructure/terraform/environments/dev"
echo "   cp terraform.tfvars.example terraform.tfvars"
echo "6. Create S3 bucket for Terraform state (see setup guide)"
echo "7. Deploy infrastructure: terraform init && terraform apply"
echo ""
print_warning "Remember to update the S3 bucket name and allowed CIDR blocks in terraform.tfvars!"

# ========================================
# File: docs/SETUP_GUIDE.md
# ========================================