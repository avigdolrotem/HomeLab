# Simplified RDS Module - infrastructure/terraform/modules/rds/outputs.tf

output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.main.id
}

output "db_instance_arn" {
  description = "The RDS instance ARN"
  value       = aws_db_instance.main.arn
}

output "db_instance_endpoint" {
  description = "The RDS instance endpoint"
  value       = aws_db_instance.main.endpoint
}

output "db_instance_port" {
  description = "The RDS instance port"
  value       = aws_db_instance.main.port
}

output "database_name" {
  description = "Name of the initial database"
  value       = aws_db_instance.main.db_name
}

output "master_username" {
  description = "Master username"
  value       = aws_db_instance.main.username
  sensitive   = true
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.main.name
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

# Master secret ARN only (app secrets created by Ansible)
output "master_secret_arn" {
  description = "ARN of the master database secret"
  value       = aws_secretsmanager_secret.rds_master.arn
}

output "master_secret_name" {
  description = "Name of the master database secret"
  value       = aws_secretsmanager_secret.rds_master.name
}