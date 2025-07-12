output "vaultwarden_instance_profile_name" {
  value       = aws_iam_instance_profile.vaultwarden.name
}

output "vaultwarden_sg_id" {
  value       = aws_security_group.vaultwarden.id
  description = "ID of the Vaultwarden EC2 security group"
}

output "subnet_id" {
  value = module.vpc.subnet_id
}

output "db_username" {
  value = var.username
}

output "db_password" {
  value = random_password.db_password.result
  sensitive = true
}

output "db_endpoint" {
  value = aws_db_instance.vaultwarden.endpoint
}

output "db_name" {
  value = var.db_name
}
