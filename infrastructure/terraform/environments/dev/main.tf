# Updated infrastructure/terraform/environments/dev/main.tf

terraform {
  backend "s3" {
    bucket         = "homelab-terraform-state-874888505976"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "HomeLab"
      Environment = var.environment
      Owner       = "Rotem Avigdol"
      ManagedBy   = "Terraform"
      AutoStop    = "true"
      CostCenter  = "Learning"
    }
  }
}

# Data sources for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"
  
  project_name        = var.project_name
  environment         = var.environment
  vpc_cidr           = var.vpc_cidr
  public_subnet_cidr = var.public_subnet_cidr
  availability_zone  = data.aws_availability_zones.available.names[0]
  
  # Add a private subnet for RDS
  private_subnet_cidr = var.private_subnet_cidr
  private_availability_zone = data.aws_availability_zones.available.names[1]
}

# Security Group Module
module "security_group" {
  source = "../../modules/security-group"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  
  # Allow your home IP
  allowed_cidr_blocks = var.allowed_cidr_blocks
}

# RDS Module
module "rds" {
  source = "../../modules/rds"
  
  project_name           = var.project_name
  environment            = var.environment
  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = [module.vpc.public_subnet_id, module.vpc.private_subnet_id]
  ec2_security_group_id  = module.security_group.security_group_id
  allowed_cidr_blocks    = var.allowed_cidr_blocks
  
  # RDS Configuration
  instance_class             = "db.t3.micro"  # Free tier
  allocated_storage          = 20             # Free tier limit
  backup_retention_period    = 7
  deletion_protection        = false          # Allow destroy for dev
  skip_final_snapshot       = true           # Allow destroy without snapshot
  publicly_accessible       = false          # Security best practice
}

# IAM Module (Updated for single secret)
module "iam" {
  source = "../../modules/iam"
  
  project_name = var.project_name
  environment  = var.environment
  s3_bucket_name = var.s3_bucket_name
  
  # Pass only the master secret ARN
  secrets_manager_arns = module.rds.master_secret_arn
}

# S3 Module
module "s3" {
  source = "../../modules/s3"
  
  project_name = var.project_name
  environment  = var.environment
  bucket_name  = var.s3_bucket_name
}

# EC2 Module
module "ec2" {
  source = "../../modules/ec2"
  
  project_name           = var.project_name
  environment            = var.environment
  instance_type          = var.instance_type
  key_name              = var.key_name
  subnet_id             = module.vpc.public_subnet_id
  security_group_ids    = [module.security_group.security_group_id]
  iam_instance_profile  = module.iam.instance_profile_name
  
  # Pass RDS and S3 info via user data
  user_data_base64 = base64encode(templatefile("${path.module}/user-data.sh", {
    s3_bucket_name = var.s3_bucket_name
    rds_endpoint   = module.rds.db_instance_endpoint
    aws_region     = var.aws_region
  }))
}

# Lambda Scheduler Module (for auto start/stop)
module "lambda_scheduler" {
  source = "../../modules/lambda-scheduler"
  
  project_name = var.project_name
  environment  = var.environment
  instance_id  = module.ec2.instance_id
  
  # Schedule: Start at 8 AM, Stop at 8 PM (Israel time)
  start_schedule = "cron(0 6 * * ? *)"  # 8 AM Israel = 6 AM UTC
  stop_schedule  = "cron(0 18 * * ? *)" # 8 PM Israel = 6 PM UTC
}

# Route53 DNS Records
data "aws_route53_zone" "main" {
  name = var.domain_name  
}

# Create A records for subdomains
resource "aws_route53_record" "subdomains" {
  for_each = toset([
    "passwords",
    "mail", 
    "files",
    "monitor",
    "jenkins",
    "whoami",
    "traefik"
  ])
  
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "${each.value}.avigdol.com"
  type    = "A"
  ttl     = 300
  records = [module.ec2.public_ip]
}