# Cloud-Native DevOps Portfolio

A comprehensive DevOps portfolio project demonstrating modern cloud-native infrastructure, automation, and best practices using AWS, Terraform, Ansible, Docker, Kubernetes, and GitOps workflows.

## 🎯 Project Overview

This project showcases enterprise-grade DevOps practices through a fully automated cloud infrastructure deployment. It demonstrates proficiency in Infrastructure as Code, container orchestration, CI/CD pipelines, monitoring, and cloud security best practices.

**What This Project Demonstrates:**
- **Infrastructure as Code** with Terraform modules and best practices
- **Configuration Management** using Ansible with idempotent playbooks
- **Container Orchestration** with both Docker Compose and Kubernetes
- **Cloud Security** with IAM roles, secrets management, and network isolation
- **Monitoring & Observability** with Prometheus, Grafana, and centralized logging
- **Backup & Disaster Recovery** with automated S3 backups and restore procedures
- **Cost Optimization** through auto-scheduling and resource tagging
- **GitOps Workflow** with automated testing and deployment pipelines

## 🚀 Technology Stack

### **Infrastructure & Cloud**
- **AWS** - EC2, RDS, S3, Lambda, Route53, IAM, Secrets Manager
- **Terraform** - Infrastructure as Code with modular design
- **Ansible** - Configuration management and application deployment

### **Container Platform**
- **Docker** - Initial deployment with Docker Compose
- **Kubernetes** - Production-ready orchestration with Minikube
- **Helm** - Package management for Kubernetes applications

### **Applications**
- **Vaultwarden** - Self-hosted password manager
- **Nextcloud** - File synchronization and collaboration
- **Grafana** - Monitoring dashboards and visualization  
- **Jenkins** - CI/CD automation server
- **Prometheus** - Metrics collection and alerting
- **Traefik** - Cloud-native reverse proxy and load balancer

### **Security & Compliance**
- **AWS IAM** - Least-privilege access control
- **Let's Encrypt** - Automated SSL/TLS certificates
- **Secrets Manager** - Centralized secrets management
- **Security Groups** - Network-level security

## 📋 Prerequisites

- **AWS Account** with programmatic access
- **Domain name** for SSL certificates (configured for avigdol.com)
- **Local Environment:**
  - AWS CLI v2+
  - Terraform 1.6+
  - Ansible 2.14+
  - Git

## 🛠️ Quick Start

### 1. Clone and Setup
```bash
git clone <repository-url>
cd homelab-portfolio
./scripts/setup.sh
```

### 2. Configure Infrastructure
```bash
cd infrastructure/terraform/environments/dev
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your AWS settings
```

### 3. Deploy Infrastructure
```bash
# Deploy AWS infrastructure
terraform init
terraform plan
terraform apply

# Configure and deploy applications
cd ../../../ansible
ansible-playbook -i inventories/aws_ec2.yml playbooks/site.yml
```

### 4. Access Applications
- **Password Manager**: https://passwords.example.com
- **File Storage**: https://files.example.com  
- **Monitoring**: https://monitor.example.com
- **CI/CD**: https://jenkins.example.com

## 🎛️ Deployment Modes

This project supports two deployment approaches:

### Docker Compose Mode (Default)
- **Use case**: Quick deployment, development, testing
- **Command**: `ansible-playbook playbooks/site.yml`
- **Features**: All applications containerized with shared PostgreSQL RDS

### Kubernetes Mode (Production-Ready)  
- **Use case**: Production deployment, advanced orchestration
- **Command**: `ansible-playbook playbooks/site.yml -e deploy_mode=k8s`
- **Features**: Minikube cluster with Helm charts, advanced networking

## 📊 Cost Optimization

- **Estimated monthly cost**: $8-15 (after AWS free tier)
- **Auto-scheduling**: Lambda functions start/stop EC2 12 hours daily (66% savings)
- **S3 lifecycle policies**: Automatic transition to cheaper storage tiers
- **Right-sized resources**: t3.micro instances, optimized storage

## 🔒 Security Features

- **Network Security**: VPC with private subnets, security groups with minimal ports
- **Data Encryption**: EBS volumes and RDS encrypted at rest
- **Secrets Management**: AWS Secrets Manager for database credentials
- **SSL/TLS**: Automatic certificate generation and renewal
- **Backup Strategy**: Automated daily backups to S3 with retention policies

## 🧪 Testing & CI/CD

- **Infrastructure Testing**: Terraform validation and planning
- **Configuration Testing**: Ansible playbook syntax validation
- **Application Health Checks**: Automated service verification
- **GitHub Actions**: Automated testing on pull requests

## 📈 Monitoring & Observability

- **Metrics**: Prometheus collecting application and system metrics
- **Visualization**: Grafana dashboards for infrastructure and applications
- **Logging**: Centralized logging with structured formats
- **Alerting**: Threshold-based alerts for critical metrics

## 🗂️ Project Structure

```
├── infrastructure/
│   ├── terraform/           # Infrastructure as Code
│   │   ├── modules/         # Reusable Terraform modules
│   │   └── environments/    # Environment-specific configurations
│   └── ansible/             # Configuration management
│       ├── roles/           # Ansible roles for different components
│       └── playbooks/       # Deployment orchestration
├── applications/
│   ├── docker-compose/      # Container orchestration with Docker
│   ├── kubernetes/          # K8s manifests and Helm charts
│   └── configs/             # Application configurations
├── scripts/                 # Automation and utility scripts
├── docs/                    # Comprehensive documentation
└── .github/                 # CI/CD workflows and templates
```

## 🎓 Learning Outcomes

This project demonstrates proficiency in:

1. **Cloud Architecture**: Designing scalable, secure cloud infrastructure
2. **Infrastructure as Code**: Managing infrastructure through version control
3. **Container Technologies**: Docker containerization and Kubernetes orchestration  
4. **Automation**: End-to-end deployment automation with Ansible
5. **Security Best Practices**: Implementing defense-in-depth strategies
6. **Monitoring**: Building comprehensive observability solutions
7. **Cost Management**: Optimizing cloud spending through automation
8. **Documentation**: Creating maintainable, professional documentation

## 🚀 Future Enhancements

- [ ] **Multi-environment support** (staging, production)
- [ ] **Advanced monitoring** with custom metrics and SLOs
- [ ] **Backup verification** with automated restore testing
- [ ] **High availability** with multi-AZ deployment
- [ ] **Container security** scanning and compliance
- [ ] **GitOps workflow** with ArgoCD or Flux

## 📞 Support & Contributing

This project is maintained as a portfolio demonstration. While it's designed to be fully functional, it serves primarily as a showcase of DevOps capabilities and best practices.

For questions about implementation or to discuss the technical decisions made in this project, feel free to reach out.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Built with ❤️ as a DevOps Portfolio Project**  
*Demonstrating modern cloud-native infrastructure and automation practices*