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
