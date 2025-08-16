variable "zone_id"      { type = string }
variable "root_domain"  { type = string }
variable "dkim_selector" {
  type    = string
  default = "mail"
}

variable "dkim_txt_value" {
  type    = string
  default = "" # paste DKIM once generated
}

# MX record pointing to mail.<root>
resource "aws_route53_record" "mx" {
  zone_id = var.zone_id
  name    = var.root_domain
  type    = "MX"
  ttl     = 300
  records = ["10 mail.${var.root_domain}."]
}

# SPF (conservative)
resource "aws_route53_record" "spf" {
  zone_id = var.zone_id
  name    = var.root_domain
  type    = "TXT"
  ttl     = 300
  records = ["v=spf1 mx -all"]
}

# DMARC
resource "aws_route53_record" "dmarc" {
  zone_id = var.zone_id
  name    = "_dmarc.${var.root_domain}"
  type    = "TXT"
  ttl     = 300
  records = ["v=DMARC1; p=quarantine; rua=mailto:dmarc@${var.root_domain}; ruf=mailto:dmarc@${var.root_domain}; fo=1; adkim=s; aspf=s"]
}

# TLS-RPT
resource "aws_route53_record" "tlsrpt" {
  zone_id = var.zone_id
  name    = "_smtp._tls.${var.root_domain}"
  type    = "TXT"
  ttl     = 300
  records = ["v=TLSRPTv1; rua=mailto:tlsrpt@${var.root_domain}"]
}

# MTA-STS policy pointer (id bumps when you re-apply)
resource "aws_route53_record" "mta_sts" {
  zone_id = var.zone_id
  name    = "_mta-sts.${var.root_domain}"
  type    = "TXT"
  ttl     = 300
  records = ["v=STSv1; id=${timestamp()}"]
}

# DKIM (add when ready)
resource "aws_route53_record" "dkim" {
  count   = length(var.dkim_txt_value) > 0 ? 1 : 0
  zone_id = var.zone_id
  name    = "${var.dkim_selector}._domainkey.${var.root_domain}"
  type    = "TXT"
  ttl     = 300
  records = [var.dkim_txt_value]
}
