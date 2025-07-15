#!/bin/bash
set -euo pipefail

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S'): $1" | tee -a /var/log/user-data.log
}

log "Starting HomeLab user-data script for Amazon Linux 2023..."

# Update system
log "Updating system packages..."
dnf update -y

# Install basic packages
log "Installing basic packages..."
if ! dnf install -y git wget unzip htop vim docker --allowerasing 2>&1 | tee -a /var/log/user-data.log; then
    log "ERROR: Failed to install basic packages - continuing anyway"
fi

# Start and enable Docker
log "Configuring Docker..."
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose v2
log "Installing Docker Compose v2..."
# Method 1: Try dnf first
if dnf install -y docker-compose-plugin; then
    log "Docker Compose installed via dnf"
else
    log "Installing Docker Compose manually..."
    DOCKER_CONFIG=/home/ec2-user/.docker
    sudo -u ec2-user mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" \
        -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    chown -R ec2-user:ec2-user $DOCKER_CONFIG
fi

# Install AWS CLI (might already be included in AL2023)
if ! command -v aws &> /dev/null; then
    log "Installing AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    ./aws/install
    rm -rf aws awscliv2.zip
fi

# Install kubectl
log "Installing kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl

# Create health check script
log "Creating health check script..."
cat > /home/ec2-user/health-check.sh << 'EOF'
#!/bin/bash
echo "=== HomeLab Health Check ==="
echo "Timestamp: $(date)"
echo ""

# Check Docker
if systemctl is-active --quiet docker; then
    echo "✅ Docker is running"
    docker version --format 'Docker: {{.Server.Version}}'
else
    echo "❌ Docker is not running"
fi

# Check Docker Compose
if docker compose version &> /dev/null; then
    echo "✅ Docker Compose available"
    docker compose version --short
else
    echo "❌ Docker Compose not available"
fi

# Check K3s
if systemctl is-active --quiet k3s; then
    echo "✅ K3s is running"
    export KUBECONFIG=/home/ec2-user/.kube/config
    kubectl get nodes 2>/dev/null || echo "⚠️  kubectl not configured properly"
else
    echo "❌ K3s is not running"
fi

echo "=== Health Check Complete ==="
EOF

chmod +x /home/ec2-user/health-check.sh
chown ec2-user:ec2-user /home/ec2-user/health-check.sh

# Create directories
sudo -u ec2-user mkdir -p /home/ec2-user/{homelab,backups,.kube}

# Stop conflicting services (postfix might not exist in AL2023)
systemctl stop postfix 2>/dev/null || log "Postfix not found (this is normal for AL2023)"
systemctl disable postfix 2>/dev/null || true

# Install K3s (simplified)
log "Installing K3s..."
curl -sfL https://get.k3s.io | INSTALL_K3S_SKIP_SELINUX_RPM=true sh -s - --write-kubeconfig-mode 644

# Configure kubectl for ec2-user
if [ -f /etc/rancher/k3s/k3s.yaml ]; then
    cp /etc/rancher/k3s/k3s.yaml /home/ec2-user/.kube/config
    chown -R ec2-user:ec2-user /home/ec2-user/.kube
    
    # Fix the server URL in the config
    sed -i 's|server: https://127.0.0.1:6443|server: https://127.0.0.1:6443|g' /home/ec2-user/.kube/config
    log "kubectl configured successfully"
else
    log "Warning: K3s config file not found"
fi

# Test installations
log "Testing installations..."
docker --version >> /var/log/user-data.log
sudo -u ec2-user docker compose version >> /var/log/user-data.log 2>&1 || log "Docker Compose test failed"
kubectl version --client >> /var/log/user-data.log 2>&1 || log "kubectl test failed"
sudo -u ec2-user kubectl get nodes >> /var/log/user-data.log 2>&1 || log "K3s test failed"

# Signal completion
touch /home/ec2-user/user-data-complete
chown ec2-user:ec2-user /home/ec2-user/user-data-complete

log "User-data script completed successfully!"