variable "route53_zone_id" {
  description = "The Route 53 hosted zone ID for your-domain.com"
  type        = string
}
variable "mail_backup_bucket_name" {
  description = "S3 bucket name for mailserver backups"
  type        = string
}
variable "placeholder_ip" {
  description = "Temporary IP for initial DNS; replace after EC2 launches"
  type        = string
  default     = "0.0.0.0"
}
variable "region" {
  description = "The AWS region where resources will be deployed"
  type        = string
  default     = "eu-central-1"
}

variable "profile" {
  description = "The name of the AWS CLI profile to use for authentication and credentials"
  type        = string
}

variable "mail_backup_bucket_prefix" {
  description = "The prefix (folder) in the S3 bucket for mailserver backups"
  type        = string
}