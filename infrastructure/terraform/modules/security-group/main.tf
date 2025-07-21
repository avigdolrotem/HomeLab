resource "aws_security_group" "main" {
  name        = "${var.project_name}-${var.environment}-sg"
  description = "Security group for ${var.project_name} ${var.environment}"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "SSH access"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }
    # HTTP access
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "testing access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Email ports for mailserver
  ingress {
    from_port   = 25
    to_port     = 25
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SMTP"
  }

  ingress {
    from_port   = 587
    to_port     = 587
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SMTP Submission"
  }

  ingress {
    from_port   = 993
    to_port     = 993
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "IMAP SSL"
  }

  ingress {
    from_port   = 995
    to_port     = 995
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "POP3 SSL"
  }

  # Kubernetes API (for K3s)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Kubernetes API"
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "All outbound traffic"
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-sg"
  }
}