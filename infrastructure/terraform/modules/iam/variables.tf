# Updated IAM Module - infrastructure/terraform/modules/iam/variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "s3_bucket_name" {
  description = "S3 bucket name for permissions"
  type        = string
}

variable "rds_instance_arn" {
  description = "RDS instance ARN for permissions"
  type        = string
  default     = "*"
}

variable "secrets_manager_arns" {
  description = "ARN of the master database secret"
  type        = string
  default     = "*"
}