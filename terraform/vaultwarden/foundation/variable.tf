variable "route53_zone_id" {
  description = "The Route 53 hosted zone ID for your-domain.com"
  type        = string
}
variable "vaultwarden_backup_bucket_name" {
  description = "S3 bucket name for vaultwarden backups"
  type        = string
}
variable "vaultwarden_backup_bucket_prefix" {
  description = "The prefix (folder) in the S3 bucket for vaultwarden backups"
  type        = string
}
variable "placeholder_ip" {
  description = "Temporary IP for initial DNS; replace after EC2 launches"
  type        = string
}
variable "region" {
  description = "The AWS region where resources will be deployed"
  type        = string
}
variable "profile" {
  description = "The name of the AWS CLI profile to use for authentication and credentials"
  type        = string
}

variable "tags" {
  description = "Global tags for all resources"
  type        = map(string)
}
variable "db_name" {
  description = "Database Name"
  type        = string
}
variable "identifier" {
  description = "This is your DB's unique name"
  type        = string
}
variable "engine" {
  description = "Type of the DB"
  type        = string
}
variable "engine_version" {
  description = "Engine version of your engine"
  type        = string
}
variable "instance_class" {
  description = "Instance class/type of DB instance"
  type        = string
}
variable "allocated_storage" {
  description = "Storage for DB in GB"
  type        = number
}
variable "username" {
  description = "User name for DB access"
  type        = string
}
variable "skip_final_snapshot" {
  description = "Skip final snapshot on destroy"
  type        = bool
}
variable "storage_type" {
  description = "Storage type to use in DB"
  type        = string
}
variable "deletion_protection" {
  description = "Protect from accidental deletion"
  type        = bool
}

variable "rds_sg_name" {
  description = "Name of RDS sg"
  type        = string
}
variable "rds_sg_description" {
  description = "Description of RDS sg"
  type        = string
}
variable "db_subnet_group_name" {
  description = "The name of the db subnet group"
  type        = string
}
variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
}
variable "vpc_name" {
  description = "VPC Name"
  type        = string
}
variable "subnet_cidr_block" {
  description = "Subnet CIDR block"
  type        = string
}
variable "subnet_name" {
  description = "Subnet name"
  type        = string
}
variable "map_public_ip_on_launch" {
  description = "Auto-assign public IP on launch"
  type        = bool
}
variable "igw_name" {
  description = "Internet Gateway name"
  type        = string
}
variable "route_table_name" {
  description = "Route Table name"
  type        = string
}
variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames"
  type        = bool
}
variable "enable_dns_support" {
  description = "Enable DNS support"
  type        = bool
}

# Vaultwarden SG variables
variable "vaultwarden_sg_name" {
  description = "Name for the Vaultwarden security group"
  type        = string
}
variable "vaultwarden_sg_description" {
  description = "Description for the Vaultwarden security group"
  type        = string
}
variable "vaultwarden_ssh_cidr_blocks" {
  description = "List of CIDR blocks allowed to SSH to Vaultwarden EC2"
  type        = list(string)
}


variable "subnet_private_a_cidr_block" {
  description = "CIDR block of private subnet A"
  type        = string
}
variable "subnet_private_b_cidr_block" {
  description = "CIDR block of private subnet B"
  type        = string
}
variable "availability_zone_a" {
  description = "First availability zone"
  type        = string
}
variable "availability_zone_b" {
  description = "Second availability zone"
  type        = string
}


