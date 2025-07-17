terraform {
  backend "s3" {
    bucket         = "homelab-terraform-state-874888505976"
    key            = "dev/terraform.tfstate"
    region         = "us-east-1"
    use_lockfile   = true
    encrypt        = true
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
}

# Security Group Module
module "security_group" {
  source = "../../modules/security-group"
  
  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id
  
  # Allow your home IP (replace with your actual IP)
  allowed_cidr_blocks = var.allowed_cidr_blocks
}

# IAM Module
module "iam" {
  source = "../../modules/iam"
  
  project_name = var.project_name
  environment  = var.environment
  s3_bucket_name = var.s3_bucket_name
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
  
#   # User data script for initial setup
#   user_data_base64 = base64encode(templatefile("${path.module}/user-data.sh", {   Disabled for now !!
#     s3_bucket_name = var.s3_bucket_name
#   }))
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

# # Add to main.tf
# resource "aws_route53_zone" "main" {
#   name = "avigdol.com"
  
#   tags = {
#     Name = "${var.project_name}-${var.environment}-zone"
#   }
# }
data "aws_route53_zone" "main" {
  name         = var.domain_name  
}
# Create A records for subdomains
resource "aws_route53_record" "subdomains" {
  for_each = toset([
    "passwords",
    "mail", 
    "files",
    "monitor",
    "jenkins"
  ])
  
  zone_id = data.aws_route53_zone.main.zone_id #Uncomment if using Route53 zone  
  name    = "${each.value}.avigdol.com"
  type    = "A"
  ttl     = 300
  records = [module.ec2.public_ip]
}