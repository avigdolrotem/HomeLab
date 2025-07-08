# --- After first apply, update foundation mail_a record to point to new EC2 IP ---
# (manually, or automate with script)

output "vaultwarden_public_ip" {value = module.vaultwarden_instance.public_ip}
