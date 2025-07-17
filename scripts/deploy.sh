#!/bin/bash
set -e

echo "=== HomeLab Deployment ==="

# Deploy infrastructure
echo "1. Deploying Terraform..."
cd infrastructure/terraform/environments/dev
terraform apply -auto-approve
PUBLIC_IP=$(terraform output -raw instance_public_ip)
echo "   Instance ready: ${PUBLIC_IP}"

# Wait for SSH
echo "2. Waiting for SSH access..."
while ! ssh -i ~/.ssh/homelab-key.pem -o ConnectTimeout=5 ubuntu@${PUBLIC_IP} echo "ready" >/dev/null 2>&1; do
    echo -n "."
    sleep 5
done
echo " Ready!"

# Configure with Ansible
echo "3. Configuring with Ansible..."
cd ../../../ansible

# Test dynamic inventory
echo "   Testing inventory..."
ansible-inventory --list

# Run configuration
ansible-playbook playbooks/site.yml

echo "=== Deployment Complete ==="
echo "SSH: ssh -i ~/.ssh/homelab-key.pem ubuntu@${PUBLIC_IP}"