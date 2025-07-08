terraform {
  backend "s3" {
    bucket         = "your-bucket"
    key            = "tfstate/mailserver/foundation.tfstate"
    region         = "eu-central-1"
    encrypt        = true
    dynamodb_table = "your-db-table" #for tflock
  }
}

# --- Route 53 DNS (for mailserver) ---
resource "aws_route53_record" "mail_a" {
  zone_id = var.route53_zone_id
  name    = "mail"
  type    = "A"
  ttl     = 300
  records = [var.placeholder_ip]
  lifecycle { prevent_destroy = true }
}

resource "aws_route53_record" "mx_root" {
  zone_id = var.route53_zone_id
  name    = ""
  type    = "MX"
  ttl     = 300
  records = ["10 mail.your-domain.com."]
  lifecycle { prevent_destroy = true }
}

resource "aws_route53_record" "spf" {
  zone_id = var.route53_zone_id
  name    = ""
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 mx include:amazonses.com ~all"]
  lifecycle { prevent_destroy = true }
}

# --- SES Identity & DKIM ---
resource "aws_ses_domain_identity" "this" {
  domain = "your-domain.com"
  lifecycle { prevent_destroy = true }
}

resource "aws_ses_domain_dkim" "this" {
  domain = aws_ses_domain_identity.this.domain
  lifecycle { prevent_destroy = true }
}

resource "aws_route53_record" "ses_verification" {
  zone_id = var.route53_zone_id
  name    = "_amazonses.${aws_ses_domain_identity.this.domain}"
  type    = "TXT"
  ttl     = 600
  records = [aws_ses_domain_identity.this.verification_token]
  lifecycle { prevent_destroy = true }
}

resource "aws_route53_record" "dkim" {
  count   = 3
  zone_id = var.route53_zone_id
  name    = "${aws_ses_domain_dkim.this.dkim_tokens[count.index]}._domainkey.${aws_ses_domain_identity.this.domain}"
  type    = "CNAME"
  ttl     = 600
  records = ["${aws_ses_domain_dkim.this.dkim_tokens[count.index]}.dkim.amazonses.com"]
  lifecycle { prevent_destroy = true }
}

# --- IAM for S3 backup (for mailserver EC2) ---
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
  name        = "mailserver-s3-policy"
  description = "Allow mailserver to access its S3 prefix"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.mail_backup_bucket_name}"
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${var.mail_backup_bucket_name}/${var.mail_backup_bucket_prefix}*"
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
