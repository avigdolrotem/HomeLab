output "vpc_id" {
  value       = module.vpc.vpc_id
  description = "The VPC ID"
}

output "subnet_id" {
  value       = module.vpc.subnet_id
  description = "The public subnet ID"
}

output "security_group_id" {
  value       = module.mailserver_sg.security_group_id
  description = "The Vaultwarden security group ID"
}

output "instance_id" {
  value       = module.mailserver_instance.instance_id
  description = "The Vaultwarden EC2 instance ID"
}

output "instance_public_ip" {
  value       = module.mailserver_instance.public_ip
  description = "The public IP address of the Vaultwarden EC2 instance"
}

output "instance_public_dns" {
  value       = module.mailserver_instance.public_dns
  description = "The public DNS address of the Vaultwarden EC2 instance"
}

output "ses_domain_verification_token" {
  value = aws_ses_domain_identity.this.verification_token
}

output "ses_dkim_tokens" {
  value = aws_ses_domain_dkim.this.dkim_tokens
}
