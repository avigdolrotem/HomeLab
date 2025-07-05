variable "region" {
  description = "The AWS region where resources will be deployed"
  type        = string
  default     = "eu-central-1"
}

variable "profile" {
  description = "The name of the AWS CLI profile to use for authentication and credentials"
  type        = string
}

# VPC and networking
variable "vpc_cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}
variable "vpc_name" {
  description = "VPC Name"
  type        = string
  default     = "homelab-vpc"
}
variable "subnet_cidr_block" {
  description = "Subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}
variable "subnet_name" {
  description = "Subnet name"
  type        = string
  default     = "homelab-public-subnet"
}
variable "availability_zone" {
  description = "Availability zone"
  type        = string
  default     = "eu-central-1a"
}
variable "map_public_ip_on_launch" {
  description = "Auto-assign public IP on launch"
  type        = bool
  default     = true
}
variable "igw_name" {
  description = "Internet Gateway name"
  type        = string
  default     = "homelab-igw"
}
variable "route_table_name" {
  description = "Route Table name"
  type        = string
  default     = "homelab-public-rt"
}
variable "enable_dns_hostnames" {
  description = "Enable DNS hostnames"
  type        = bool
  default     = true
}
variable "enable_dns_support" {
  description = "Enable DNS support"
  type        = bool
  default     = true
}

# Security group
variable "sg_name" {
  description = "Security group name"
  type        = string
  default     = "vaultwarden-sg"
}
variable "sg_description" {
  description = "Security group description"
  type        = string
  default     = "Allow SSH, HTTP, and HTTPS for Vaultwarden"
}
variable "ingress_rules" {
  description = "List of ingress rules"
  type = list(object({
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}
variable "egress_rules" {
  description = "List of egress rules"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

# EC2 Instance
variable "instance_name" {
  description = "EC2 instance name"
  type        = string
  default     = "vaultwarden"
}
variable "ami" {
  description = "AMI ID for EC2 instance"
  type        = string
}
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
variable "key_name" {
  description = "EC2 SSH key pair name"
  type        = string
}
variable "user_data" {
  description = "User data script to provision instance"
  type        = string
  default     = ""
}

# Shared
variable "tags" {
  description = "Global tags for all resources"
  type        = map(string)
  default     = {}
}

variable "route53_zone_id" {
  description = "The ID of the Route53 hosted zone to manage DNS records for your domain (e.g. avigdol.com)."
  type        = string
}
