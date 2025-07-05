# --- Outputs for use in disposable layer ---
# output "mail_backup_bucket_name" { value = aws_s3_bucket.mail_backup.bucket }
output "mailserver_instance_profile_name" { value = aws_iam_instance_profile.mailserver.name }
output "mail_backup_bucket_name" {
  value = var.mail_backup_bucket_name
  description = "Name of the mailserver backup S3 bucket"
}

output "mail_backup_bucket_prefix" {
  value = var.mail_backup_bucket_prefix
  description = "Prefix for mailserver backup in the S3 bucket"
}
