#!/bin/bash
set -e

echo "🚀 Deploying HomeLab..."

# Deploy infrastructure
echo "📦 Deploying Terraform..."
cd infrastructure/terraform/environments/dev
terraform init
terraform plan
terraform apply -auto-approve

# Configure with Ansible  
echo "⚙️ Configuring with Ansible..."
cd ../../../ansible
ansible-playbook -i inventories/aws_ec2.yml playbooks/site.yml

echo "✅ Deployment complete!"