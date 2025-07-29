# Updated VPC Module - infrastructure/terraform/modules/vpc/variables.tf

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet (for RDS)"
  type        = string
}

variable "availability_zone" {
  description = "Availability zone for the public subnet"
  type        = string
}

variable "private_availability_zone" {
  description = "Availability zone for the private subnet (must be different from public)"
  type        = string
}

variable "create_nat_gateway" {
  description = "Whether to create a NAT gateway for private subnet internet access"
  type        = bool
  default     = false
}