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
