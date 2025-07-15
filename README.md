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
