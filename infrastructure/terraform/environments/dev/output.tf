# Updated infrastructure/terraform/environments/dev/outputs.tf

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.vpc.private_subnet_id
}

# EC2 Outputs
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}

output "instance_public_dns" {
  description = "Public DNS of the EC2 instance"
  value       = module.ec2.public_dns
}

output "security_group_id" {
  description = "ID of the security group"
  value       = module.security_group.security_group_id
}

# RDS Outputs
output "rds_instance_id" {
  description = "ID of the RDS instance"
  value       = module.rds.db_instance_id
}

output "rds_endpoint" {
  description = "RDS instance endpoint"
  value       = module.rds.db_instance_endpoint
}

output "rds_port" {
  description = "RDS instance port"
  value       = module.rds.db_instance_port
}

output "database_name" {
  description = "Name of the initial database"
  value       = module.rds.database_name
}

# Master secret info
output "master_secret_arn" {
  description = "ARN of the master database secret"
  value       = module.rds.master_secret_arn
  sensitive   = true
}

output "master_secret_name" {
  description = "Name of the master database secret"
  value       = module.rds.master_secret_name
}

# S3 Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket"
  value       = module.s3.bucket_name
}

# IAM Outputs
output "iam_role_name" {
  description = "Name of the IAM role"
  value       = module.iam.role_name
}

# Lambda Scheduler Outputs
output "lambda_function_name" {
  description = "Name of the Lambda scheduler function"
  value       = module.lambda_scheduler.lambda_function_name
}

# Connection Information
output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/homelab-key.pem ubuntu@${module.ec2.public_ip}"
}

output "application_urls" {
  description = "Application URLs"
  value = {
    vaultwarden = "https://passwords.avigdol.com"
    nextcloud   = "https://files.avigdol.com"
    grafana     = "https://monitor.avigdol.com"
    jenkins     = "https://jenkins.avigdol.com"
  }
}

# Deployment information for scripts
output "deployment_info" {
  description = "Information needed for deployment scripts"
  value = {
    instance_ip    = module.ec2.public_ip
    rds_endpoint   = module.rds.db_instance_endpoint
    s3_bucket_name = module.s3.bucket_name
    master_secret  = module.rds.master_secret_name
  }
}