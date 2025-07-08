terraform {
  backend "s3" {
    bucket         = "homelab-874888505976"
    key            = "tfstate/vaultwarden/foundation.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "homelab-874888505976"
  }
}

module "vpc" {
  source                  = "../../modules/vpc"
  vpc_cidr_block          = var.vpc_cidr_block
  vpc_name                = var.vpc_name
  subnet_cidr_block       = var.subnet_cidr_block
  subnet_name             = var.subnet_name
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = var.map_public_ip_on_launch
  igw_name                = var.igw_name
  route_table_name        = var.route_table_name
  enable_dns_hostnames    = var.enable_dns_hostnames
  enable_dns_support      = var.enable_dns_support
  tags                    = var.tags
}

resource "aws_subnet" "private_a" {
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = var.subnet_private_a_cidr_block
  availability_zone       = var.availability_zone_a
  map_public_ip_on_launch = false
  tags                    = merge(var.tags, { Name = "vaultwarden-private-subnet-a" })
}

resource "aws_subnet" "private_b" {
  vpc_id                  = module.vpc.vpc_id
  cidr_block              = var.subnet_private_b_cidr_block
  availability_zone       = var.availability_zone_b
  map_public_ip_on_launch = false
  tags                    = merge(var.tags, { Name = "vaultwarden-private-subnet-b" })
}

# Vaultwarden security group (for app server EC2)
resource "aws_security_group" "vaultwarden" {
  name        = var.vaultwarden_sg_name
  description = var.vaultwarden_sg_description
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.vaultwarden_ssh_cidr_blocks
  }
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

# RDS security group
resource "aws_security_group" "rds" {
  name        = var.rds_sg_name
  description = var.rds_sg_description
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = var.tags
}

resource "aws_security_group_rule" "allow_mysql_from_vaultwarden" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds.id
  source_security_group_id = aws_security_group.vaultwarden.id
  description              = "Allow MySQL from Vaultwarden EC2 SG"
}

resource "aws_db_subnet_group" "vaultwarden" {
  name       = var.db_subnet_group_name
  subnet_ids = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  tags       = { Name = var.db_subnet_group_name }
}

resource "random_password" "db_password" {
  length  = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_instance" "vaultwarden" {
  db_name                = var.db_name
  identifier             = var.identifier
  engine                 = var.engine
  engine_version         = var.engine_version
  instance_class         = var.instance_class
  allocated_storage      = var.allocated_storage
  username               = var.username
  password               = random_password.db_password.result
  db_subnet_group_name   = aws_db_subnet_group.vaultwarden.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  skip_final_snapshot    = var.skip_final_snapshot
  publicly_accessible    = false
  storage_type           = var.storage_type
  multi_az               = false
  deletion_protection    = var.deletion_protection
  tags                   = var.tags
}

resource "aws_route53_record" "passwords_a" {
  zone_id = var.route53_zone_id
  name    = "passwords"
  type    = "A"
  ttl     = 300
  records = [var.placeholder_ip]
  # lifecycle { prevent_destroy = true }
}

resource "aws_iam_role" "vaultwarden_ec2" {
  name = "vaultwarden-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "vaultwarden_s3_policy" {
  name        = "vaultwarden-s3-policy"
  description = "Allow vaultwarden to access its S3 prefix"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.vaultwarden_backup_bucket_name}"
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${var.vaultwarden_backup_bucket_name}/${var.vaultwarden_backup_bucket_prefix}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "vaultwarden_s3_attach" {
  role       = aws_iam_role.vaultwarden_ec2.name
  policy_arn = aws_iam_policy.vaultwarden_s3_policy.arn
}

resource "aws_iam_instance_profile" "vaultwarden" {
  name = "vaultwarden-instance-profile"
  role = aws_iam_role.vaultwarden_ec2.name
}
