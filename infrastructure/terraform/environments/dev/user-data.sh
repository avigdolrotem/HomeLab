#!/bin/bash
set -e

# Simple logging
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a /var/log/user-data.log
}

log "Starting HomeLab user-data script for Ubuntu..."

# Update system
log "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install basic packages
log "Installing basic packages..."
apt-get install -y git curl wget unzip htop vim

# Install Docker
log "Installing Docker..."
apt-get install -y ca-certificates gnupg lsb-release
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Start and enable Docker
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu

# Install AWS CLI v2
log "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip

# Install kubectl
log "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Create directories
mkdir -p /home/ubuntu/{homelab,backups,.kube}
chown -R ubuntu:ubuntu /home/ubuntu/

# Install K3s (optional - can be skipped if not needed)
log "Installing K3s..."
curl -sfL https://get.k3s.io | sh -s - --write-kubeconfig-mode 644

# Configure kubectl for ubuntu user
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    cp /etc/rancher/k3s/k3s.yaml /home/ubuntu/.kube/config
    chown -R ubuntu:ubuntu /home/ubuntu/.kube
    log "kubectl configured successfully"
fi

# Signal completion
touch /home/ubuntu/user-data-complete
chown ubuntu:ubuntu /home/ubuntu/user-data-complete

log "User-data script completed successfully!"

# Test installations
log "Testing installations..."
docker --version >> /var/log/user-data.log
sudo -u ubuntu docker compose version >> /var/log/user-data.log 2>&1 || log "Docker Compose test failed"
kubectl version --client >> /var/log/user-data.log 2>&1 || log "kubectl test failed"
sudo -u ubuntu kubectl get nodes >> /var/log/user-data.log 2>&1 || log "K3s test failed"

log "All tests completed!"