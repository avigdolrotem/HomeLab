variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_name" {
  description = "Name tag for the VPC"
  type        = string
  default     = "homelab-vpc"
}

variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames in the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "Enable DNS support in the VPC"
  type        = bool
  default     = true
}

variable "subnet_cidr_block" {
  description = "The CIDR block for the public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "subnet_name" {
  description = "Name tag for the public subnet"
  type        = string
  default     = "homelab-public-subnet"
}

variable "availability_zone" {
  description = "The AWS availability zone for the subnet"
  type        = string
  default     = "eu-central-1a"
}

variable "map_public_ip_on_launch" {
  description = "Assign a public IP by default to instances launched in this subnet"
  type        = bool
  default     = true
}

variable "igw_name" {
  description = "Name tag for the Internet Gateway"
  type        = string
  default     = "homelab-igw"
}

variable "route_table_name" {
  description = "Name tag for the public route table"
  type        = string
  default     = "homelab-public-rt"
}

variable "tags" {
  description = "Extra tags to apply to all resources"
  type        = map(string)
  default     = {}
}