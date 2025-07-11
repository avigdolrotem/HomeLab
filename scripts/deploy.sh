#!/bin/bash
set -e

# 1. Apply foundation
echo "Applying Terraform (foundation)..."
terraform -chdir=./terraform/vaultwarden/foundation apply -auto-approve -var-file="foundation.tfvars"

# 2. Apply disposable
echo "Applying Terraform (disposable)..."
terraform -chdir=./terraform/vaultwarden/disposable  apply -auto-approve -var-file="disposable.tfvars"

# 3. Generate dynamic inventory
VAULTWARDEN_IP=$(terraform -chdir=./terraform/vaultwarden/disposable output -raw vaultwarden_public_ip)
cat > ansible/inventory/vaultwarden_dynamic <<EOF
[vaultwarden]
$VAULTWARDEN_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/homelab-ec2-key.pem
EOF

# 4. Clean up SSH known_hosts for the new IP (avoid host key errors)
ssh-keygen -R "$VAULTWARDEN_IP"

# 5. Generate Ansible vars from Terraform outputs (replace/extend as needed)
terraform -chdir=./terraform/vaultwarden/foundation output -json \
  | jq -r 'to_entries | map("\(.key): \"\(.value.value)\"") | .[]' > ansible/group_vars/vaultwarden.yaml

# 6. Optionally add static vars if missing (manual step or merge with template as discussed earlier)

# 7. Run Ansible playbook with the new inventory
ansible-playbook -i ansible/inventory/vaultwarden_dynamic ansible/playbooks/deploy-vaultwarden.yml
