# Change to terraform directory
cd infrastructure/terraform/environments/dev
terraform destroy -auto-approve || {
    print_error "Terraform destroy failed!"
    exit 1
}