# AWS Provider settings
region  = "eu-central-1"
profile = "your-profile"

# VPC settings (point to existing VPC/subnet if already created, or use global)
vpc_cidr_block    = "10.0.0.0/16"
vpc_name          = "vpc_name"
subnet_cidr_block = "10.0.1.0/24"
subnet_name       = "subnet-name"
availability_zone = "eu-central-1a"
map_public_ip_on_launch = true
igw_name          = "igw-name"
route_table_name  = "public-rt-name"
enable_dns_hostnames = true
enable_dns_support   = true

# Security Group for Mailserver
sg_name        = "mailserver-sg"
sg_description = "Allow SSH, SMTP, Submission, IMAPS, HTTP, HTTPS for Mailserver"

ingress_rules = [
  {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description = "SMTP"
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description = "Submission"
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  },
  {
    description = "IMAPS"
    from_port   = 993
    to_port     = 993
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

egress_rules = [
  {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
]

# EC2 Instance
instance_name = "mailserver"
ami           = "ami-02003f9f0fde924ea"       
instance_type = "t2.micro"         # Increase if running in production (currently for free tier)
key_name      = "your-key-name"
user_data     = ""                 # Leave blank for Ansible setup

# Tags (add any labels you want)
tags = {
  "Environment" = ""
  "Project"     = "Mailserver"
}
route53_zone_id         = "your-route53-zone-id"
