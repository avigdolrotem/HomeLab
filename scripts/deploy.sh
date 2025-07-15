#!/bin/bash
set -euo pipefail

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

# Change to terraform directory
cd infrastructure/terraform/environments/dev

print_header "HomeLab Infrastructure Deployment"

# Check if terraform.tfvars exists
if [[ ! -f "terraform.tfvars" ]]; then
    print_error "terraform.tfvars not found!"
    print_status "Please copy terraform.tfvars.example to terraform.tfvars and update with your values"
    exit 1
fi

# Validate terraform files
print_status "Validating Terraform configuration..."
terraform fmt -check || {
    print_warning "Terraform files need formatting. Running terraform fmt..."
    terraform fmt
}

terraform validate || {
    print_error "Terraform validation failed!"
    exit 1
}

# Plan deployment
print_status "Planning infrastructure changes..."
terraform plan -out=tfplan || {
    print_error "Terraform plan failed!"
    exit 1
}

# Confirm deployment
echo ""
print_warning "Review the plan above. Do you want to apply these changes? (yes/no)"
read -r response
if [[ "$response" != "yes" ]]; then
    print_status "Deployment cancelled."
    rm -f tfplan
    exit 0
fi

# Apply changes
print_status "Applying infrastructure changes..."
terraform apply tfplan || {
    print_error "Terraform apply failed!"
    rm -f tfplan
    exit 1
}

# Clean up plan file
rm -f tfplan

# Get outputs
print_header "Deployment Complete!"
terraform output

# Get public IP for testing
PUBLIC_IP=$(terraform output -raw instance_public_ip)
print_status "Instance deployed at: $PUBLIC_IP"

# Wait for instance to be ready
print_status "Waiting for instance to complete initialization..."
sleep 30

# Test SSH connectivity
print_status "Testing SSH connectivity..."
KEY_NAME=$(terraform output -raw key_name || echo "homelab-key")
if ssh -i ~/.ssh/${KEY_NAME}.pem -o ConnectTimeout=10 -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP "echo 'SSH connection successful'"; then
    print_status "SSH connection successful!"
    
    # Run health check
    print_status "Running health check..."
    ssh -i ~/.ssh/${KEY_NAME}.pem ec2-user@$PUBLIC_IP "./health-check.sh" || print_warning "Health check script not found (this is normal for first deployment)"
else
    print_warning "SSH connection failed. Instance may still be initializing."
fi

print_header "Next Steps"
echo "1. Wait a few minutes for user-data script to complete"
echo "2. SSH to instance: ssh -i ~/.ssh/${KEY_NAME}.pem ec2-user@$PUBLIC_IP"
echo "3. Check user-data logs: sudo tail -f /var/log/user-data.log"
echo "4. Run health check: ./health-check.sh"
echo "5. Deploy applications with Docker Compose"

print_status "Deployment script completed!"
