module "vpc" {
  source            = "./modules/vpc"
  vpc_cidr_block    = var.vpc_cidr_block
  vpc_name          = var.vpc_name
  subnet_cidr_block = var.subnet_cidr_block
  subnet_name       = var.subnet_name
  availability_zone = var.availability_zone
  map_public_ip_on_launch = var.map_public_ip_on_launch
  igw_name          = var.igw_name
  route_table_name  = var.route_table_name
  tags              = var.tags
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
}

module "mailserver_sg" {
  source         = "./modules/security_group"
  name           = var.sg_name
  description    = var.sg_description
  vpc_id         = module.vpc.vpc_id
  ingress_rules  = var.ingress_rules
  egress_rules   = var.egress_rules
  tags           = var.tags
}

module "mailserver_instance" {
  source                     = "./modules/ec2"
  name                       = var.instance_name
  ami                        = var.ami
  instance_type              = var.instance_type
  subnet_id                  = module.vpc.subnet_id
  security_group_ids         = [module.mailserver_sg.security_group_id]
  key_name                   = var.key_name
  associate_public_ip_address = true
  user_data                  = ""
  tags                       = var.tags
}

# A record for mail.avigdol.com
resource "aws_route53_record" "mail_a" {
  zone_id = var.route53_zone_id
  name    = "mail"
  type    = "A"
  ttl     = 300
  records = [module.mailserver_instance.public_ip]
  lifecycle {
  prevent_destroy = true
  }
}

# MX record for avigdol.com
resource "aws_route53_record" "mx_root" {
  zone_id = var.route53_zone_id
  name    = ""           
  type    = "MX"
  ttl     = 300
  records = ["10 mail.avigdol.com."]
  lifecycle {
  prevent_destroy = true
  }
}

# SPF record
resource "aws_route53_record" "spf" {
  zone_id = var.route53_zone_id
  name    = ""            
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 mx include:amazonses.com ~all"]
  lifecycle {
  prevent_destroy = true
  }
}

resource "aws_ses_domain_identity" "this" {
  domain = "avigdol.com"
  lifecycle {
  prevent_destroy = true
  }
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
  lifecycle {
  prevent_destroy = true
  }
}

resource "aws_route53_record" "ses_verification" {
  zone_id = var.route53_zone_id
  name    = "_amazonses.${aws_ses_domain_identity.this.domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.this.verification_token]
  lifecycle {
  prevent_destroy = true
  }
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = var.route53_zone_id
  name    = "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}._domainkey.${aws_ses_domain_identity.this.domain}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.amazonses.com"]
  lifecycle {
  prevent_destroy = true
  }
}
resource "aws_iam_role" "mailserver_ec2" {
  name = "mailserver-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "mailserver_s3_policy" {
  name = "mailserver-s3-policy"
  description = "Allow mailserver to access its S3 bucket"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket"
        ]
        Resource = "arn:aws:s3:::your-bucket-name"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "arn:aws:s3:::your-bucket-name/*"
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "mailserver_s3_attach" {
  role       = aws_iam_role.mailserver_ec2.name
  policy_arn = aws_iam_policy.mailserver_s3_policy.arn
}
resource "aws_iam_instance_profile" "mailserver" {
  name = "mailserver-instance-profile"
  role = aws_iam_role.mailserver_ec2.name
}
