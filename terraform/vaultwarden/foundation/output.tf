output "vaultwarden_backup_bucket_name" {
  value       = var.vaultwarden_backup_bucket_name
  description = "S3 bucket name for vaultwarden backups"
}
output "vaultwarden_backup_bucket_prefix" {
  value       = var.vaultwarden_backup_bucket_prefix
  description = "Prefix for vaultwarden backup in the S3 bucket"
}
output "vaultwarden_instance_profile_name" {
  value       = aws_iam_instance_profile.vaultwarden.name
}
output "db_address" {
  value       = aws_db_instance.vaultwarden.address
}
output "db_username" {
  value       = aws_db_instance.vaultwarden.username
}
output "db_password" {
  value       = random_password.db_password.result
  sensitive   = true
}
output "db_name" {
  value       = aws_db_instance.vaultwarden.db_name
}
output "vaultwarden_sg_id" {
  value       = aws_security_group.vaultwarden.id
  description = "ID of the Vaultwarden EC2 security group"
}
output "subnet_id" {
  value = module.vpc.subnet_id
}