#!/bin/bash

# Set your desired timezone (optional)
timedatectl set-timezone Asia/Jerusalem

# Install Docker
apt-get update
apt-get install -y docker.io

systemctl enable --now docker

# Create Vaultwarden data directory
mkdir -p /vw-data

# Install Caddy (for Ubuntu/Debian)
apt-get install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | apt-key add -
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt-get update
apt-get install -y caddy

# Write the Caddyfile
cat >/etc/caddy/Caddyfile <<EOL
passwords.avigdol.com {
    reverse_proxy localhost:8080
}
EOL

# Ensure Caddy uses the updated Caddyfile
systemctl restart caddy

# Pull the latest Vaultwarden image
docker pull vaultwarden/server:latest

# Run Vaultwarden on port 8080 (change ADMIN_TOKEN and SIGNUPS_ALLOWED as needed)
docker run -d \
  --name vaultwarden \
  -v /vw-data:/data \
  -e ADMIN_TOKEN='YOUR_ADMIN_TOKEN' \
  -e SIGNUPS_ALLOWED=true \
  -p 8080:80 \
  vaultwarden/server:latest
