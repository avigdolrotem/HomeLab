# 2. Destroy disposable
echo "Destroying Terraform (disposable)..."
terraform -chdir=./terraform/vaultwarden/disposable  destroy -auto-approve -var-file="disposable.tfvars"

# 1. Destroy foundation
echo "Destroying Terraform (foundation)..."
terraform -chdir=./terraform/vaultwarden/foundation destroy -auto-approve -var-file="foundation.tfvars"

