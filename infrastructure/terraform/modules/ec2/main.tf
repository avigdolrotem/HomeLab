# Get the latest Ubuntu AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu*amd64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance
resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile
  user_data_base64 = var.user_data_base64

  # Storage
  root_block_device {
    volume_type = "gp3"
    volume_size = 30
    encrypted   = true
    
    tags = {
      Name = "${var.project_name}-${var.environment}-root-volume"
    }
  }

  # Additional EBS volume for application data
  ebs_block_device {
    device_name = "/dev/sdf"
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true

    tags = {
      Name = "${var.project_name}-${var.environment}-data-volume"
    }
  }

  tags = {
    Name = "${var.project_name}-${var.environment}-instance"
  }

  # Prevent accidental termination
  disable_api_termination = false

  # Enable detailed monitoring
  monitoring = true

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for consistent public IP
resource "aws_eip" "main" {
  instance = aws_instance.main.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-${var.environment}-eip"
  }

  depends_on = [aws_instance.main]
}
