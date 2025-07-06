# --- After first apply, update foundation mail_a record to point to new EC2 IP ---
# (manually, or automate with script)

output "mailserver_public_ip" { value = module.mailserver_instance.public_ip }
