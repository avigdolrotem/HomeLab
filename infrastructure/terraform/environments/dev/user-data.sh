#!/bin/bash
set -e

# Update system
yum update -y

# Install basic packages
yum install -y git curl wget unzip htop

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Create directories
mkdir -p /home/ec2-user/{homelab,backups}
chown -R ec2-user:ec2-user /home/ec2-user/

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Create a startup script
cat > /home/ec2-user/startup.sh << 'EOF'
#!/bin/bash
# This script runs when the instance starts

# Check if Docker is running
if ! systemctl is-active --quiet docker; then
    sudo systemctl start docker
fi

# Log startup
echo "$(date): Instance started" >> /home/ec2-user/startup.log
EOF

chmod +x /home/ec2-user/startup.sh
chown ec2-user:ec2-user /home/ec2-user/startup.sh

# Set up cron job for startup script
echo "@reboot /home/ec2-user/startup.sh" | crontab -u ec2-user -

# Install K3s (lightweight Kubernetes)
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644
systemctl enable k3s

# Create symlink for kubectl to use k3s
ln -s /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config 2>/dev/null || true
mkdir -p /home/ec2-user/.kube
cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
chown -R ec2-user:ec2-user /home/ec2-user/.kube

# Signal that user data script is complete
touch /home/ec2-user/user-data-complete

# Log completion
echo "$(date): User data script completed" >> /home/ec2-user/startup.log